package com.puzzak.m3x_mesh

import android.content.ContentProvider
import android.content.ContentValues
import android.content.Context
import android.database.Cursor
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import org.json.JSONObject
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference

class M3xMeshContentProvider : ContentProvider() {

    companion object {
        @Volatile
        var headlessHandler: ((caller: String, payload: String, callback: (String) -> Unit) -> Boolean)? = null

        internal fun buildJsonRpcError(code: Int, message: String): String {
            return JSONObject().apply {
                put("jsonrpc", "2.0")
                put(
                    "error",
                    JSONObject().apply {
                        put("code", code)
                        put("message", message)
                    }
                )
            }.toString()
        }
    }

    override fun onCreate(): Boolean {
        return true
    }

    override fun call(method: String, arg: String?, extras: Bundle?): Bundle? {
        val caller = callingPackage ?: "unknown"
        Log.d("M3xMesh", "[REQUEST RECEIVED] Host: ${context?.packageName} | Caller: $caller | Method: $method | Arg: $arg")

        val resultBundle = Bundle()
        val resultJson: String = when (method) {
            "call_tool" -> {
                val payload = extras?.getString("payload") ?: extras?.getString("call") ?: arg ?: "{}"
                var responseStr: String? = null
                val latch = CountDownLatch(1)
                val handler = Handler(Looper.getMainLooper())

                val appCtx = context?.applicationContext ?: context
                val metaData = appCtx?.let { M3xMeshPlugin.getApplicationMetaData(it) }
                val headlessEntrypoint = metaData
                    ?.getString(M3xMeshPlugin.META_HEADLESS_ENTRYPOINT)
                    ?.trim()
                    ?.takeIf { it.isNotEmpty() }
                val requiresForegroundOverlay = metaData
                    ?.getBoolean(M3xMeshPlugin.META_REQUIRES_FOREGROUND_OVERLAY, false)
                    ?: false
                val overlayActivityMeta = metaData
                    ?.getString(M3xMeshPlugin.META_OVERLAY_ACTIVITY)
                    ?.trim()
                    ?.takeIf { it.isNotEmpty() }

                var readyHost = M3xMeshPlugin.findReadyHost()
                var nativeHeadlessResult: String? = null
                if (readyHost == null && !requiresForegroundOverlay) {
                    val nativeHeadless = headlessHandler
                    if (nativeHeadless != null) {
                        val headlessLatch = CountDownLatch(1)
                        val headlessResponse = AtomicReference<String?>(null)
                        try {
                            val handled = nativeHeadless.invoke(caller, payload) { res ->
                                headlessResponse.compareAndSet(null, res)
                                headlessLatch.countDown()
                            }
                            if (handled) {
                                Log.d(
                                    "M3xMesh",
                                    "[HEADLESS NATIVE DISPATCH] Host: ${context?.packageName} | Caller: $caller"
                                )
                                nativeHeadlessResult = try {
                                    val completed = headlessLatch.await(15, TimeUnit.SECONDS)
                                    if (!completed) {
                                        buildJsonRpcError(
                                            -32603,
                                            "Headless tool execution timed out in host application."
                                        )
                                    } else {
                                        headlessResponse.get() ?: buildJsonRpcError(
                                            -32603,
                                            "Null response received from headless handler."
                                        )
                                    }
                                } catch (e: InterruptedException) {
                                    Thread.currentThread().interrupt()
                                    buildJsonRpcError(
                                        -32603,
                                        "Interrupted waiting for headless tool result: ${e.message}"
                                    )
                                }
                            }
                        } catch (t: Throwable) {
                            Log.e(
                                "M3xMesh",
                                "[HEADLESS NATIVE ERROR] Host: ${context?.packageName} | Caller: $caller | Error: ${t.message}",
                                t
                            )
                            nativeHeadlessResult = buildJsonRpcError(
                                -32603,
                                "Headless handler error: ${t.message ?: t::class.java.simpleName}"
                            )
                        }
                    }
                }

                if (nativeHeadlessResult != null) {
                    nativeHeadlessResult
                } else {
                    if (readyHost == null && !requiresForegroundOverlay && headlessEntrypoint != null && appCtx != null) {
                        readyHost = M3xMeshPlugin.ensureHeadlessHostReady(appCtx, timeoutSeconds = 6L)
                    }

                    if (readyHost != null) {
                        val targetHost = readyHost
                        handler.post {
                            M3xMeshPlugin.dispatchIncomingCall(caller, payload, host = targetHost) { res ->
                                responseStr = res
                                latch.countDown()
                            }
                        }
                        try {
                            val completed = latch.await(15, TimeUnit.SECONDS)
                            if (!completed) {
                                """{"jsonrpc":"2.0","error":{"code":-32603,"message":"Tool execution timed out in host application."}}"""
                            } else {
                                responseStr ?: """{"jsonrpc":"2.0","error":{"code":-32603,"message":"Null response received from host application."}}"""
                            }
                        } catch (e: InterruptedException) {
                            """{"jsonrpc":"2.0","error":{"code":-32603,"message":"Interrupted waiting for tool result: ${e.message}"}}"""
                        }
                    } else {
                        val resolvedOverlay = appCtx?.let { ctx ->
                            M3xMeshPlugin.resolveOverlayComponent(
                                ctx,
                                targetPkg = ctx.packageName,
                                explicitActivity = overlayActivityMeta,
                                allowLaunchFallback = false
                            )
                        }
                        if (appCtx != null && (requiresForegroundOverlay || resolvedOverlay != null)) {
                            Log.d(
                                "M3xMesh",
                                "[HEADLESS_OVERLAY_REQUIRED] Host plugin instance is null for ${appCtx.packageName}, signaling caller to launch foreground overlay (${resolvedOverlay?.className ?: "dynamic"})."
                            )
                            val headlessBundle = Bundle().apply {
                                putString("status", "HEADLESS_OVERLAY_REQUIRED")
                                putString("overlay_package", appCtx.packageName)
                                if (resolvedOverlay != null) {
                                    putString("overlay_activity", resolvedOverlay.className)
                                }
                                putString("response", """{"jsonrpc":"2.0","error":{"code":-32001,"message":"HEADLESS_OVERLAY_REQUIRED"}}""")
                            }
                            return headlessBundle
                        } else {
                            Log.d("M3xMesh", "[APP_NOT_RUNNING] Host plugin instance is null for ${context?.packageName}, returning error.")
                            val bundle = Bundle().apply {
                                putString("status", "APP_NOT_RUNNING")
                                putString("response", """{"jsonrpc":"2.0","error":{"code":-32603,"message":"Application '${context?.packageName}' is not running."}}""")
                            }
                            return bundle
                        }
                    }
                }
            }
            "query_tools" -> {
                val liveTools = M3xMeshPlugin.declaredToolsJson
                val prefsTools = context
                    ?.getSharedPreferences("m3x_mesh_prefs", Context.MODE_PRIVATE)
                    ?.getString("declared_tools", null)

                when {
                    liveTools.isNotBlank() && liveTools != "[]" -> liveTools
                    !prefsTools.isNullOrBlank() && prefsTools != "[]" -> prefsTools
                    else -> {
                        try {
                            context?.assets?.open("flutter_assets/assets/mesh_tools.json")
                                ?.bufferedReader()
                                ?.use { it.readText().trim() }
                                ?.takeIf { it.isNotBlank() }
                                ?: "[]"
                        } catch (_: Exception) {
                            "[]"
                        }
                    }
                }
            }
            else -> {
                """{"jsonrpc":"2.0","error":{"code":-32601,"message":"Unsupported ContentProvider method: $method"}}"""
            }
        }

        Log.d("M3xMesh", "[RESPONSE SENT] Host: ${context?.packageName} | To: $caller | Response: $resultJson")
        resultBundle.putString("response", resultJson)
        return resultBundle
    }

    override fun query(
        uri: Uri,
        projection: Array<out String>?,
        selection: String?,
        selectionArgs: Array<out String>?,
        sortOrder: String?
    ): Cursor? = null

    override fun getType(uri: Uri): String? = null

    override fun insert(uri: Uri, values: ContentValues?): Uri? = null

    override fun delete(uri: Uri, selection: String?, selectionArgs: Array<out String>?): Int = 0

    override fun update(
        uri: Uri,
        values: ContentValues?,
        selection: String?,
        selectionArgs: Array<out String>?
    ): Int = 0
}
