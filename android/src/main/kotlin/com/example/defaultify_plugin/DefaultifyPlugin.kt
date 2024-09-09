package com.example.defaultify_plugin


import android.Manifest
import android.annotation.TargetApi
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.util.Log
import androidx.activity.result.ActivityResult
import androidx.core.app.ActivityCompat
import com.defaultify.Defaultify
import com.defaultify.DefaultifyActivity
import com.defaultify.EventApplication

import com.defaultify.baseclass.ShakeDetectorNewCallBack
import com.defaultify.network.model.requestPayload.DeviceDetailsPayload
import com.defaultify.network.model.requestPayload.NetworkTraceInfo
import com.defaultify.screenRecording.DefaultifyDataManager
import com.defaultify.utils.IntentConstant


import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.text.SimpleDateFormat
import java.time.ZoneId
import java.time.ZonedDateTime
import java.time.format.DateTimeFormatter
import java.util.Date
import java.util.Locale


class DefaultifyPlugin: FlutterPlugin, MethodCallHandler,ActivityAware,PluginRegistry.RequestPermissionsResultListener, PluginRegistry.ActivityResultListener {

  private lateinit var channel: MethodChannel
  private var activity: Activity? = null
  private var result: MethodChannel.Result? = null
  private lateinit var context: Context
  private  var shakeDetector: ShakeDetectorNewCallBack? = null
  private lateinit var appToken:String

  private var dftyDataManager : DefaultifyDataManager?=null



  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "defaultify_plugin")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      "launch" -> launch(call, result)
      "handleShakeEvent" -> {
        handleShakeEvent(call.arguments as? Map<String, Any>)
      }
      "onLifecycleChange" -> {
        val state = call.argument<String>("state")
        Log.d("PlugBug", "Lifecycle state changed: $state")
        handleLifecycleChange(state)
        result.success(null)
      }
      "logException" -> {
        logException(call, result)
      }

      "log"->{
        log(call, result)
      }
      "registerNetworkEvent"->{
        Log.e("registerNetworkEventGet","registerNetworkEvent")
        registerNetworkEvent(call, result)
      }
      else -> result.notImplemented()
    }
  }


  private fun registerNetworkEvent(call: MethodCall, result: MethodChannel.Result) {
    val eventData = call.arguments as? Map<String, Any>
    eventData?.let {eventData->
      val networkEvent= NetworkTraceInfo()
      val requestTime =
        getParamOrDefault<Long>(eventData, "timestamp", System.currentTimeMillis()).toString()

      networkEvent.requestTime =changeFormat(requestTime)
      networkEvent.requestMethod = getParamOrDefault<String>(eventData, "method", "")
      networkEvent.requestURL = getParamOrDefault<String>(eventData, "url", "")
      networkEvent.response = getParamOrDefault<String>(eventData, "body", "")
      networkEvent.responseStatus= getParamOrDefault<Int>(eventData, "status", 200)
      networkEvent.requestPayload = getParamOrDefault<String>(eventData, "requestPayload", "")
      networkEvent.requestHeaders = parseHeaders(eventData["headers"] as? Map<String, String>)
      networkEvent.responseHeaders = parseResponseHeaders(eventData["responseHeaders"] as? Map<String, String>)
      EventApplication.networkList.add(networkEvent)


    }

  }

  private fun changeFormat(requestTime: String): String? {
    return try {
      // Parse the string to a long timestamp
      val timestamp = requestTime.toLong()
      // Convert timestamp to a readable date-time format
      val date = Date(timestamp)
      val format = SimpleDateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'", Locale.getDefault())
      format.format(date)
    } catch (e: NumberFormatException) {
      // If parsing fails, use the current system time
      val date = Date(System.currentTimeMillis())
      val format = SimpleDateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'", Locale.getDefault())
      format.format(date)
    }
  }
  private fun <T> getParamOrDefault(
    params: Map<String, Any>,
    paramName: String,
    defaultValue: T
  ): T {
    val value = params[paramName] ?: return defaultValue
    return value as T
  }

  private fun parseHeaders(headersMap: Map<String, String>?): NetworkTraceInfo.RequestHeaders {
    return NetworkTraceInfo.RequestHeaders(
      headersMap?.get("accept-language"),
      headersMap?.get("authorization"),
      headersMap?.get("content-length"),
      headersMap?.get("content-type"),
      headersMap?.get("timezone"),
      headersMap?.get("Platform"),
      headersMap?.get("device-token")
    )
  }


  private fun parseResponseHeaders(headersMap: Map<String, String>?): NetworkTraceInfo.ResponseHeaders {
    return NetworkTraceInfo.ResponseHeaders(
      headersMap?.get("access-control-allow-origin"),
      headersMap?.get("content-length"),
      null,
      headersMap?.get("content-type"),
      null,null,null,convertDateHeader(headersMap?.get("date")),null,null,null,null,null,null,headersMap?.get("x-amz-apigw-id"),null,
      headersMap?.get("x-amzn-trace-id"),null,null,null,null,null,null,null,null,null
    )


  }

  @TargetApi(Build.VERSION_CODES.O)
  private fun convertDateHeader(dateHeader: String?): String? {
    return try {
      dateHeader?.let {
        val formatter = DateTimeFormatter.RFC_1123_DATE_TIME
        val gmtTime = ZonedDateTime.parse(it, formatter)
        val localTime = gmtTime.withZoneSameInstant(ZoneId.systemDefault())
        DateTimeFormatter.RFC_1123_DATE_TIME.format(localTime)
      }
    } catch (e: Exception) {
      null // Return null if parsing fails
    }
  }



  private fun log(call: MethodCall, result: MethodChannel.Result) {
    val reason: String? = call.argument("text")
    result.success(null)
  }
  private class FlutterManagedException(message: String?) : Exception(message) {
    companion object {
      private const val serialVersionUID = 1L
    }
  }
  private fun logException(call: MethodCall, result: MethodChannel.Result) {
    val name: String? = call.argument("location")
    val reason: String? = call.argument("reason")
    val stackTrace: List<String>? = call.argument("stackTrace") ?: emptyList()

    Defaultify.logException(reason,name,stackTrace)
    result.success(null)
  }

  private fun handleShakeEvent(arguments: Map<String, Any>?) {
    // Get URI from Flutter, perform actions
    val uri = arguments?.get("uri") as? String

    val screenList = arguments?.get("screenList") as? List<Map<String, String>>

    val topViewList = ArrayList<DeviceDetailsPayload.Metadata.TopView>()

    if (screenList != null) {
      for (screen in screenList) {
        val screenName = screen["screenName"]
        val startTime = screen["startTime"]

        val topView = DeviceDetailsPayload.Metadata.TopView(
          startTime,null,
          screenName
        )
        topViewList.add(topView)
      }
    }
    EventApplication.topViewList=topViewList

    if (!uri.isNullOrEmpty()) {
      val intent = Intent(activity, DefaultifyActivity::class.java)
      intent.putExtra(IntentConstant.URI, uri)
      intent.putExtra("platform_key", "Flutter")
      activity?.startActivity(intent)
    } else {
      val intent = Intent(activity, DefaultifyActivity::class.java)
      intent.putExtra("platform_key", "Flutter")
      activity?.startActivity(intent)
    }

    EventApplication.isDFTFYActivityOpen = true
    activity?.let { Defaultify.stopRecording(it) }

  }

  private fun handleLifecycleChange(state: String?) {
    // Perform actions based on lifecycle state
    when (state) {
      "AppLifecycleState.resumed" -> {
        // App is in foreground
        Log.e("AppLifecycleState", "App is in foreground"+EventApplication.isFromDFTFYActivity)

        activity?.let {
          if (EventApplication.isFromDFTFYActivity) {
            EventApplication.isFromDFTFYActivity =false
            Log.e("AppLifecycleState", "App Resume")
            dftyDataManager = DefaultifyDataManager(it,"Flutter")
            dftyDataManager?.permissionBridge{
              askPermission()
            }
          }

          Defaultify.onResumeState(it, dftyDataManager)


        }
      }
      "AppLifecycleState.paused" -> {
        // App is in background
        Log.e("AppLifecycleState", " App is in background")
        activity?.let { Defaultify.onBackgroundState(it) }
      }
      "AppLifecycleState.inactive" -> {
        // App is inactive
        Log.e("AppLifecycleState", "AppLifecycleState.inactive")
      }
      "AppLifecycleState.detached" -> {
        // App is detached
        Log.e("AppLifecycleState", "AppLifecycleState.detached")
        activity?.let { Defaultify.onDestroyState(it) }
      }
    }
  }
  private fun launch(call: MethodCall, result: MethodChannel.Result) {
    this.result = result
    appToken =  call.argument<String>("token") ?: ""
    startDFTFY()

  }
  private fun requestPermissions() {
    val permissions = if (android.os.Build.VERSION.SDK_INT >= 33) {
      arrayOf(
        Manifest.permission.READ_MEDIA_AUDIO,
        Manifest.permission.READ_MEDIA_VIDEO,
        Manifest.permission.READ_MEDIA_IMAGES
      )
    } else {
      arrayOf(
        Manifest.permission.READ_EXTERNAL_STORAGE,
        Manifest.permission.WRITE_EXTERNAL_STORAGE
      )
    }
    ActivityCompat.requestPermissions(
      activity!!,
      permissions,
      PERMISSION_REQUEST_CODE
    )
  }

  private fun startDFTFY() {

    activity?.let {
      dftyDataManager= DefaultifyDataManager(it,"Flutter")
      dftyDataManager?.permissionBridge{
        askPermission()
      }
      Defaultify.launch(it, appToken,dftyDataManager)

    }
    if(shakeDetector ==null) {
      shakeDetector = activity?.let { ShakeDetectorNewCallBack(it) }
      shakeDetector?.setCallback {
        onShake()
      }
      shakeDetector?.initializeAccelerometerSensor()
    }
    result?.success(1)
  }

  private fun startRecording() {
    val mediaProjectionManager: MediaProjectionManager =
      activity?.getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
    val permissionIntent: Intent = mediaProjectionManager.createScreenCaptureIntent()
    activity?.startActivityForResult(permissionIntent, SCREEN_RECORD_REQUEST_CODE)
  }


  override fun onRequestPermissionsResult(
    requestCode: Int,
    permissions: Array<out String>,
    grantResults: IntArray
  ): Boolean {
    if (requestCode == PERMISSION_REQUEST_CODE) {
      if (grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }) {
        startRecording()
      } else {
        result?.error("PERMISSION_DENIED", "Permissions were not granted", null)
      }
      return true
    }/* else {
      startDFTFY()
    }*/

    return false
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
    binding.addRequestPermissionsResultListener(this)
    binding.addActivityResultListener(this)


  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
    if(shakeDetector ==null) {
      shakeDetector = ShakeDetectorNewCallBack(activity!!)
      shakeDetector?.setCallback {
        onShake()
      }
      shakeDetector?.initializeAccelerometerSensor()
    }
  }

  override fun onDetachedFromActivity() {
    activity?.let { Defaultify.onDestroyState(it) }
    activity = null
    shakeDetector=null
  }

  override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
    if (requestCode == SCREEN_RECORD_REQUEST_CODE) {
      if (resultCode == Activity.RESULT_OK) {
        EventApplication.isRecordingPermissionPopUpShown = false
        EventApplication.result = ActivityResult(resultCode, data)
        dftyDataManager?.startRecordingPlugin()
        return true
      }
      else if(resultCode == Activity.RESULT_CANCELED){
        EventApplication.isRecordingPermissionDenied = true
        EventApplication.isRecordingPermissionPopUpShown = false
        dftyDataManager?.startRecordingPlugin()
        return true
      }

    }
    return false
  }

  companion object {
    private const val PERMISSION_REQUEST_CODE = 101
    private const val SCREEN_RECORD_REQUEST_CODE = 102

  }
  /*override*/ fun onShake() {
    activity?.let {
      // Notify Flutter about the shake event
      if(EventApplication.isScreenShotEnable)
        channel.invokeMethod("handleShakeEvent", null)
      else
      {
        val intent = Intent(activity, DefaultifyActivity::class.java)
        intent.putExtra("platform_key", "Flutter")
        it.startActivity(intent)
      }
    }
  }
  fun askPermission() {
    requestPermissions()

  }
}
