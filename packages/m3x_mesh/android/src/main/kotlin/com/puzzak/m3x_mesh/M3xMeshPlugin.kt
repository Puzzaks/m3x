package com.puzzak.m3x_mesh

import android.app.Activity
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.util.Log
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import org.json.JSONArray
import org.json.JSONObject
import java.util.concurrent.CopyOnWriteArrayList
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

class M3xMeshPlugin : FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.ActivityResultListener {
    private lateinit var channel: MethodChannel
    private var context: Context? = null
    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var pendingActivityResult: Result? = null
    private val ioExecutor = java.util.concurrent.Executors.newCachedThreadPool()
    private val mainHandler = android.os.Handler(android.os.Looper.getMainLooper())

    @Volatile
    var isToolHostReady: Boolean = false

    companion object {
        private const val CHANNEL_NAME = "com.puzzak.m3x_mesh"
        private const val TAG = "M3xMesh"
        private const val REQUEST_CODE_OVERLAY = 0x4D33
        private const val ACTION_MESH_NODE = "com.puzzak.m3x.mesh.ACTION_MESH_NODE"
        private const val ACTION_MESH_OVERLAY = "com.puzzak.m3x.mesh.ACTION_MESH_OVERLAY"
        internal const val META_HEADLESS_ENTRYPOINT = "com.puzzak.m3x.mesh.HEADLESS_ENTRYPOINT"
        internal const val META_REQUIRES_FOREGROUND_OVERLAY = "com.puzzak.m3x.mesh.REQUIRES_FOREGROUND_OVERLAY"
        internal const val META_OVERLAY_ACTIVITY = "com.puzzak.m3x.mesh.OVERLAY_ACTIVITY"

        @Volatile
        var declaredToolsJson: String = "[]"

        private val activeInstances = CopyOnWriteArrayList<M3xMeshPlugin>()
        private val headlessLock = Any()

        @Volatile
        private var headlessEngine: FlutterEngine? = null

        @Volatile
        private var headlessReadyLatch: CountDownLatch? = null

        @Volatile
        var instance: M3xMeshPlugin? = null

        fun findReadyHost(): M3xMeshPlugin? {
            return activeInstances.lastOrNull { it.isToolHostReady && it.activity != null }
                ?: activeInstances.lastOrNull { it.isToolHostReady }
        }

        private fun updateActiveInstance() {
            instance = findReadyHost()
        }

        private fun notifyHostReady() {
            headlessReadyLatch?.countDown()
        }

        internal fun getApplicationMetaData(
            appContext: Context,
            packageName: String = appContext.packageName
        ): Bundle? {
            return try {
                val pm = appContext.packageManager
                val appInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    pm.getApplicationInfo(
                        packageName,
                        PackageManager.ApplicationInfoFlags.of(PackageManager.GET_META_DATA.toLong())
                    )
                } else {
                    @Suppress("DEPRECATION")
                    pm.getApplicationInfo(packageName, PackageManager.GET_META_DATA)
                }
                appInfo.metaData
            } catch (_: Exception) {
                null
            }
        }

        private fun resolveHeadlessEntrypoint(appContext: Context): String? {
            return getApplicationMetaData(appContext)
                ?.getString(META_HEADLESS_ENTRYPOINT)
                ?.trim()
                ?.takeIf { it.isNotEmpty() }
        }

        internal fun discoverMeshPackages(pm: PackageManager): List<String> {
            val meshApps = LinkedHashSet<String>()

            // 1. Dynamic decentralized discovery via ACTION_MESH_NODE Intent Content Providers
            try {
                val meshIntent = Intent(ACTION_MESH_NODE)
                val resolveInfos = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    pm.queryIntentContentProviders(
                        meshIntent,
                        PackageManager.ResolveInfoFlags.of(0)
                    )
                } else {
                    @Suppress("DEPRECATION")
                    pm.queryIntentContentProviders(meshIntent, 0)
                }
                for (info in resolveInfos) {
                    val pkg = info.providerInfo?.packageName
                    if (!pkg.isNullOrBlank()) {
                        meshApps.add(pkg)
                    }
                }
            } catch (e: Exception) {
                Log.w(TAG, "queryIntentContentProviders failed: ${e.message}")
            }

            // 2. Query installed providers matching .mesh authority
            try {
                val providers = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    pm.queryContentProviders(
                        null,
                        0,
                        PackageManager.ComponentInfoFlags.of(PackageManager.GET_META_DATA.toLong())
                    )
                } else {
                    @Suppress("DEPRECATION")
                    pm.queryContentProviders(null, 0, PackageManager.GET_META_DATA)
                }
                for (p in providers) {
                    val auth = p.authority
                    if (auth != null && auth.endsWith(".mesh") && p.packageName.isNotBlank()) {
                        meshApps.add(p.packageName)
                    }
                }
            } catch (e: Exception) {
                Log.w(TAG, "queryContentProviders failed: ${e.message}")
            }

            return ArrayList(meshApps)
        }

        internal fun normalizeActivityClassName(packageName: String, activityName: String): String {
            return if (activityName.startsWith(".")) "$packageName$activityName" else activityName
        }

        private fun isActivityAvailable(pm: PackageManager, comp: ComponentName): Boolean {
            return try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    pm.getActivityInfo(comp, PackageManager.ComponentInfoFlags.of(0))
                } else {
                    @Suppress("DEPRECATION")
                    pm.getActivityInfo(comp, 0)
                }
                true
            } catch (_: PackageManager.NameNotFoundException) {
                try {
                    val probe = Intent().setComponent(comp)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        pm.resolveActivity(probe, PackageManager.ResolveInfoFlags.of(0)) != null
                    } else {
                        @Suppress("DEPRECATION")
                        pm.resolveActivity(probe, 0) != null
                    }
                } catch (_: Exception) {
                    false
                }
            } catch (_: Exception) {
                false
            }
        }

        private fun resolveIntentComponent(pm: PackageManager, intent: Intent): ComponentName? {
            return try {
                val info = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    pm.resolveActivity(intent, PackageManager.ResolveInfoFlags.of(PackageManager.MATCH_DEFAULT_ONLY.toLong()))
                } else {
                    @Suppress("DEPRECATION")
                    pm.resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY)
                }
                val activityInfo = info?.activityInfo
                if (activityInfo != null && activityInfo.packageName.isNotBlank() && activityInfo.name.isNotBlank()) {
                    ComponentName(activityInfo.packageName, activityInfo.name)
                } else {
                    null
                }
            } catch (_: Exception) {
                null
            }
        }

        private fun queryIntentComponents(pm: PackageManager, intent: Intent): List<ComponentName> {
            return try {
                val infos = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    pm.queryIntentActivities(intent, PackageManager.ResolveInfoFlags.of(PackageManager.MATCH_DEFAULT_ONLY.toLong()))
                } else {
                    @Suppress("DEPRECATION")
                    pm.queryIntentActivities(intent, PackageManager.MATCH_DEFAULT_ONLY)
                }
                infos.mapNotNull { info ->
                    val ai = info.activityInfo
                    if (ai != null && ai.packageName.isNotBlank() && ai.name.isNotBlank()) {
                        ComponentName(ai.packageName, ai.name)
                    } else {
                        null
                    }
                }
            } catch (_: Exception) {
                emptyList()
            }
        }

        internal fun resolveTargetPackage(pm: PackageManager, targetApp: String): String? {
            val clean = targetApp
                .removePrefix("content://")
                .removeSuffix(".mesh")
                .trim()
            if (clean.isEmpty()) return null
            if (clean.contains('.')) {
                return clean
            }
            val discovered = discoverMeshPackages(pm)
            return discovered.firstOrNull { it.equals(clean, ignoreCase = true) }
                ?: discovered.firstOrNull { it.endsWith(".$clean", ignoreCase = true) }
        }

        internal fun resolveOverlayComponent(
            appContext: Context,
            targetPkg: String?,
            explicitActivity: String? = null,
            allowLaunchFallback: Boolean = false
        ): ComponentName? {
            val pm = appContext.packageManager
            val normalizedPkg = targetPkg?.trim()?.takeIf { it.isNotEmpty() }
            val normalizedActivity = explicitActivity?.trim()?.takeIf { it.isNotEmpty() }

            // 1. Explicit component if caller/provider supplied both package & activity
            if (normalizedPkg != null && normalizedActivity != null) {
                val explicitComp = ComponentName(
                    normalizedPkg,
                    normalizeActivityClassName(normalizedPkg, normalizedActivity)
                )
                if (isActivityAvailable(pm, explicitComp)) {
                    return explicitComp
                }
            }

            // 2. Dynamic mesh overlay capability (ACTION_MESH_OVERLAY)
            if (normalizedPkg != null) {
                resolveIntentComponent(pm, Intent(ACTION_MESH_OVERLAY).setPackage(normalizedPkg))
                    ?.let { return it }
            } else {
                queryIntentComponents(pm, Intent(ACTION_MESH_OVERLAY)).firstOrNull()
                    ?.let { return it }
            }

            // 3. System Assistant capability (ACTION_ASSIST) scoped to target package or discovered mesh nodes
            if (normalizedPkg != null) {
                resolveIntentComponent(pm, Intent(Intent.ACTION_ASSIST).setPackage(normalizedPkg))
                    ?.let { return it }
            } else {
                for (meshPkg in discoverMeshPackages(pm)) {
                    resolveIntentComponent(pm, Intent(ACTION_MESH_OVERLAY).setPackage(meshPkg))
                        ?.let { return it }
                    resolveIntentComponent(pm, Intent(Intent.ACTION_ASSIST).setPackage(meshPkg))
                        ?.let { return it }
                }
            }

            // 4. Manifest <application> meta-data OVERLAY_ACTIVITY
            if (normalizedPkg != null) {
                val metaActivity = getApplicationMetaData(appContext, normalizedPkg)
                    ?.getString(META_OVERLAY_ACTIVITY)
                    ?.trim()
                    ?.takeIf { it.isNotEmpty() }
                if (metaActivity != null) {
                    val metaComp = ComponentName(
                        normalizedPkg,
                        normalizeActivityClassName(normalizedPkg, metaActivity)
                    )
                    if (isActivityAvailable(pm, metaComp)) {
                        return metaComp
                    }
                }
            }

            // 5. Optional safe fallback to target package's launcher activity
            if (allowLaunchFallback && normalizedPkg != null) {
                val launchComp = try {
                    pm.getLaunchIntentForPackage(normalizedPkg)?.component
                } catch (_: Exception) {
                    null
                }
                if (launchComp != null && isActivityAvailable(pm, launchComp)) {
                    return launchComp
                }
            }

            return null
        }

        fun ensureHeadlessHostReady(appContext: Context, timeoutSeconds: Long = 6L): M3xMeshPlugin? {
            findReadyHost()?.let { return it }
            if (android.os.Looper.myLooper() == android.os.Looper.getMainLooper()) {
                return findReadyHost()
            }
            val entrypointName = resolveHeadlessEntrypoint(appContext) ?: return null

            val latch: CountDownLatch
            synchronized(headlessLock) {
                findReadyHost()?.let { return it }
                val existingLatch = headlessReadyLatch
                if (existingLatch != null && headlessEngine != null) {
                    latch = existingLatch
                } else {
                    latch = CountDownLatch(1)
                    headlessReadyLatch = latch
                    val mainHandler = android.os.Handler(android.os.Looper.getMainLooper())
                    mainHandler.post {
                        try {
                            if (findReadyHost() != null) {
                                latch.countDown()
                                return@post
                            }
                            val loader = FlutterInjector.instance().flutterLoader()
                            if (!loader.initialized()) {
                                loader.startInitialization(appContext)
                                loader.ensureInitializationComplete(appContext, null)
                            }
                            val bundlePath = loader.findAppBundlePath()
                            val engine = FlutterEngine(appContext)
                            headlessEngine = engine
                            Log.d(TAG, "[HEADLESS COLD-BOOT] Starting entrypoint '$entrypointName' for ${appContext.packageName}")
                            engine.dartExecutor.executeDartEntrypoint(
                                DartExecutor.DartEntrypoint(bundlePath, entrypointName)
                            )
                        } catch (e: Exception) {
                            Log.e(TAG, "[HEADLESS COLD-BOOT ERROR] ${e.message}", e)
                            headlessEngine = null
                            headlessReadyLatch = null
                            latch.countDown()
                        }
                    }
                }
            }

            try {
                latch.await(timeoutSeconds, TimeUnit.SECONDS)
            } catch (_: InterruptedException) {}

            val ready = findReadyHost()
            if (ready == null) {
                synchronized(headlessLock) {
                    val staleEngine = headlessEngine
                    headlessEngine = null
                    headlessReadyLatch = null
                    if (staleEngine != null) {
                        android.os.Handler(android.os.Looper.getMainLooper()).post {
                            try {
                                staleEngine.destroy()
                            } catch (_: Exception) {}
                        }
                    }
                }
            }
            return ready
        }

        fun dispatchIncomingCall(
            callingPackage: String,
            payload: String,
            host: M3xMeshPlugin? = findReadyHost(),
            callback: (String) -> Unit
        ) {
            val plugin = host
            if (plugin == null) {
                callback("""{"jsonrpc":"2.0","error":{"code":-32603,"message":"Target application is not running."}}""")
                return
            }

            val callData = mapOf(
                "caller" to callingPackage,
                "payload" to payload
            )

            plugin.channel.invokeMethod("onIncomingToolCall", callData, object : Result {
                override fun success(result: Any?) {
                    when (result) {
                        is String -> callback(result)
                        is Map<*, *> -> callback(JSONObject(result).toString())
                        null -> callback("""{"jsonrpc":"2.0","result":null}""")
                        else -> callback(result.toString())
                    }
                }

                override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                    callback("""{"jsonrpc":"2.0","error":{"code":-32603,"message":"$errorCode: $errorMessage"}}""")
                }

                override fun notImplemented() {
                    callback("""{"jsonrpc":"2.0","error":{"code":-32601,"message":"onIncomingToolCall not implemented in host application."}}""")
                }
            })
        }
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
        if (!activeInstances.contains(this)) {
            activeInstances.add(this)
        }
        updateActiveInstance()
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        isToolHostReady = false
        channel.setMethodCallHandler(null)
        activeInstances.remove(this)
        updateActiveInstance()
        context = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addActivityResultListener(this)
        updateActiveInstance()
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding?.removeActivityResultListener(this)
        activity = null
        activityBinding = null
        updateActiveInstance()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addActivityResultListener(this)
        updateActiveInstance()
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeActivityResultListener(this)
        activity = null
        activityBinding = null
        updateActiveInstance()
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == REQUEST_CODE_OVERLAY) {
            val responseStr = data?.getStringExtra("response")
            Log.d(TAG, "[ACTIVITY RESULT] Overlay response received (resultCode=$resultCode): $responseStr")
            val pending = pendingActivityResult
            pendingActivityResult = null
            if (responseStr != null) {
                pending?.success(responseStr)
            } else {
                val errCode = if (resultCode == Activity.RESULT_CANCELED) "OVERLAY_CANCELLED" else "OVERLAY_FAILED"
                pending?.error(errCode, "Mesh overlay finished without returning a response", null)
            }
            return true
        }
        return false
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        val appContext = context ?: run {
            result.error("NO_CONTEXT", "Application context is null", null)
            return
        }

        when (call.method) {
            "markToolHostReady" -> {
                val ready = call.argument<Boolean>("ready") ?: true
                isToolHostReady = ready
                updateActiveInstance()
                if (ready) {
                    notifyHostReady()
                }
                Log.d(TAG, "[HOST READY] ${appContext.packageName} ready=$ready (activity=${activity != null})")
                result.success(true)
            }

            "setDeclaredTools" -> {
                val tools = call.argument<Any>("tools")
                declaredToolsJson = when (tools) {
                    is String -> tools
                    is List<*> -> JSONArray(tools).toString()
                    is Map<*, *> -> JSONObject(tools).toString()
                    else -> "[]"
                }
                appContext.getSharedPreferences("m3x_mesh_prefs", Context.MODE_PRIVATE)
                    .edit()
                    .putString("declared_tools", declaredToolsJson)
                    .apply()
                Log.d(TAG, "[SET DECLARED TOOLS] updated declared tools JSON (${declaredToolsJson.length} bytes)")
                result.success(true)
            }

            "callContentProvider" -> {
                val uriStr = call.argument<String>("uri")
                if (uriStr.isNullOrEmpty()) {
                    result.error("INVALID_URI", "ContentProvider URI cannot be null or empty", null)
                    return
                }

                val callObj = call.argument<Any>("call")
                val payload = when (callObj) {
                    is String -> callObj
                    is Map<*, *> -> JSONObject(callObj).toString()
                    else -> "{}"
                }

                val bundle = Bundle().apply {
                    putString("payload", payload)
                }

                Log.d(TAG, "[OUTGOING DISPATCH] Target: $uriStr | Payload: $payload")
                ioExecutor.execute {
                    try {
                        val parsedUri = Uri.parse(uriStr)
                        val resultBundle = appContext.contentResolver.call(parsedUri, "call_tool", payload, bundle)
                        val statusStr = resultBundle?.getString("status")
                        val responseStr = resultBundle?.getString("response")

                        if (statusStr == "HEADLESS_OVERLAY_REQUIRED" || responseStr?.contains("HEADLESS_OVERLAY_REQUIRED") == true) {
                            Log.d(TAG, "[HEADLESS_OVERLAY_REQUIRED] Launching foreground overlay from caller activity")
                            mainHandler.post {
                                val currentActivity = activity
                                if (currentActivity != null) {
                                    val explicitPkg = resultBundle?.getString("overlay_package")
                                        ?.trim()
                                        ?.takeIf { it.isNotEmpty() }
                                    val explicitActivity = resultBundle?.getString("overlay_activity")
                                        ?.trim()
                                        ?.takeIf { it.isNotEmpty() }
                                    val authorityPkg = parsedUri.authority?.let { auth ->
                                        try {
                                            appContext.packageManager.resolveContentProvider(auth, 0)?.packageName
                                        } catch (_: Exception) {
                                            null
                                        } ?: auth.removeSuffix(".mesh").takeIf { it.isNotBlank() }
                                    }
                                    val targetPkg = explicitPkg ?: authorityPkg
                                    val resolvedComponent = resolveOverlayComponent(
                                        appContext,
                                        targetPkg = targetPkg,
                                        explicitActivity = explicitActivity,
                                        allowLaunchFallback = true
                                    )

                                    if (resolvedComponent == null) {
                                        Log.e(TAG, "[HEADLESS_OVERLAY_REQUIRED] No overlay or launchable activity found for package '$targetPkg'.")
                                        result.success("""{"jsonrpc":"2.0","error":{"code":-32603,"message":"No overlay activity available for package '${targetPkg ?: "unknown"}'."}}""")
                                        return@post
                                    }

                                    val intent = Intent().apply {
                                        component = resolvedComponent
                                        putExtra("caller", appContext.packageName)
                                        putExtra("payload", payload)
                                    }

                                    pendingActivityResult?.error("SUPERSEDED", "New overlay request started", null)
                                    pendingActivityResult = result
                                    try {
                                        currentActivity.startActivityForResult(intent, REQUEST_CODE_OVERLAY)
                                    } catch (e: Exception) {
                                        Log.e(TAG, "Failed to start overlay activity: ${e.message}", e)
                                        pendingActivityResult = null
                                        result.error("LAUNCH_FAILED", "Failed to launch overlay: ${e.message}", null)
                                    }
                                } else {
                                    Log.e(TAG, "No foreground activity available to launch overlay")
                                    result.error("NO_ACTIVITY", "Caller has no foreground activity to launch overlay", null)
                                }
                            }
                            return@execute
                        }

                        Log.d(TAG, "[OUTGOING RESPONSE] Target: $uriStr | Response: $responseStr")
                        mainHandler.post {
                            result.success(responseStr)
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "[OUTGOING ERROR] Target: $uriStr | Error: ${e.message}", e)
                        mainHandler.post {
                            result.error("CALL_FAILED", e.message, null)
                        }
                    }
                }
            }

            "queryMeshTools" -> {
                val uriStr = call.argument<String>("uri")
                if (uriStr.isNullOrEmpty()) {
                    result.error("INVALID_URI", "ContentProvider URI cannot be null or empty", null)
                    return
                }

                Log.d(TAG, "[OUTGOING QUERY] Target: $uriStr")
                ioExecutor.execute {
                    try {
                        val parsedUri = Uri.parse(uriStr)
                        val resultBundle = appContext.contentResolver.call(parsedUri, "query_tools", null, null)
                        val responseStr = resultBundle?.getString("response") ?: "[]"
                        Log.d(TAG, "[OUTGOING QUERY RESPONSE] Target: $uriStr | Response: $responseStr")
                        mainHandler.post {
                            result.success(responseStr)
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "[OUTGOING QUERY ERROR] Target: $uriStr | Error: ${e.message}", e)
                        mainHandler.post {
                            result.error("QUERY_FAILED", e.message, null)
                        }
                    }
                }
            }

            "listMeshApps" -> {
                try {
                    val meshApps = discoverMeshPackages(appContext.packageManager)
                    Log.d(TAG, "[LIST MESH APPS] Found: $meshApps")
                    result.success(meshApps)
                } catch (e: Exception) {
                    Log.e(TAG, "[LIST MESH APPS ERROR] ${e.message}", e)
                    result.error("LIST_FAILED", e.message, null)
                }
            }

            "isPackageInstalled" -> {
                val pkg = call.argument<String>("packageName") ?: call.argument<String>("package") ?: ""
                val pm = appContext.packageManager
                try {
                    pm.getPackageInfo(pkg, 0)
                    result.success(true)
                } catch (_: Exception) {
                    try {
                        result.success(pm.resolveContentProvider("$pkg.mesh", 0) != null)
                    } catch (_: Exception) {
                        result.success(false)
                    }
                }
            }

            "getAppLabel" -> {
                val pkg = call.argument<String>("package") ?: call.argument<String>("packageName")
                if (pkg.isNullOrBlank()) {
                    result.success(null)
                    return
                }
                try {
                    val pm = appContext.packageManager
                    val appInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        pm.getApplicationInfo(pkg, PackageManager.ApplicationInfoFlags.of(0))
                    } else {
                        @Suppress("DEPRECATION")
                        pm.getApplicationInfo(pkg, 0)
                    }
                    result.success(pm.getApplicationLabel(appInfo).toString())
                } catch (_: Exception) {
                    result.success(null)
                }
            }

            "getAppIcon" -> {
                try {
                    val pm = appContext.packageManager
                    val drawable = pm.getApplicationIcon(appContext.packageName)
                    val bitmap = if (drawable is android.graphics.drawable.BitmapDrawable) {
                        drawable.bitmap
                    } else {
                        val width = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else 144
                        val height = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else 144
                        val bmp = android.graphics.Bitmap.createBitmap(width, height, android.graphics.Bitmap.Config.ARGB_8888)
                        val canvas = android.graphics.Canvas(bmp)
                        drawable.setBounds(0, 0, canvas.width, canvas.height)
                        drawable.draw(canvas)
                        bmp
                    }
                    val stream = java.io.ByteArrayOutputStream()
                    bitmap.compress(android.graphics.Bitmap.CompressFormat.PNG, 100, stream)
                    result.success(stream.toByteArray())
                } catch (e: Exception) {
                    result.error("ICON_ERROR", e.message, null)
                }
            }

            "openAssistantBubble" -> {
                try {
                    val pm = appContext.packageManager
                    val explicitPkg = (call.argument<String>("overlayPkg")
                        ?: call.argument<String>("overlayPackage")
                        ?: call.argument<String>("packageName"))
                        ?.trim()
                        ?.takeIf { it.isNotEmpty() }
                    val explicitActivity = call.argument<String>("overlayActivity")
                        ?.trim()
                        ?.takeIf { it.isNotEmpty() }
                    val targetApp = call.argument<String>("targetApp")
                        ?.trim()
                        ?.takeIf { it.isNotEmpty() }

                    val resolvedPkg: String? = when {
                        explicitPkg != null -> explicitPkg
                        targetApp != null -> resolveTargetPackage(pm, targetApp)
                        else -> null
                    }

                    if ((explicitPkg != null || targetApp != null) && resolvedPkg == null) {
                        Log.w(TAG, "[OPEN ASSISTANT BUBBLE] Target app '$targetApp' was not found among installed mesh nodes")
                        result.success(false)
                        return
                    }

                    val resolvedComponent = resolveOverlayComponent(
                        appContext,
                        targetPkg = resolvedPkg,
                        explicitActivity = explicitActivity,
                        allowLaunchFallback = true
                    )

                    if (resolvedComponent == null) {
                        Log.w(TAG, "[OPEN ASSISTANT BUBBLE] No overlay or assistant activity resolved (targetApp=$targetApp, pkg=$resolvedPkg)")
                        result.success(false)
                        return
                    }

                    val prompt = call.argument<String>("prompt")
                    val contextData = call.argument<String>("contextData")
                    val imageBase64 = call.argument<String>("imageBase64")
                    val imageUri = call.argument<String>("imageUri")
                    val downsample = call.argument<Boolean>("downsample") ?: true

                    val intent = Intent().apply {
                        component = resolvedComponent
                        putExtra("interactive_bubble", true)
                        putExtra("caller", appContext.packageName)
                        if (prompt != null) putExtra("prompt", prompt)
                        if (contextData != null) putExtra("context_data", contextData)
                        if (imageBase64 != null) putExtra("image_base64", imageBase64)
                        if (imageUri != null) putExtra("image_uri", imageUri)
                        putExtra("downsample", downsample)
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }

                    val currentActivity = activity
                    if (currentActivity != null) {
                        currentActivity.startActivity(intent)
                    } else {
                        appContext.startActivity(intent)
                    }
                    Log.d(TAG, "[OPEN ASSISTANT BUBBLE] Launched ${resolvedComponent.flattenToShortString()} in interactive mode")
                    result.success(true)
                } catch (e: Exception) {
                    Log.e(TAG, "[OPEN ASSISTANT BUBBLE ERROR] ${e.message}", e)
                    result.error("BUBBLE_LAUNCH_FAILED", e.message, null)
                }
            }

            else -> result.notImplemented()
        }
    }
}
