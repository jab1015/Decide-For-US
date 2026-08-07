package com.decideforus.app

import android.os.Build
import com.google.android.play.agesignals.AgeSignalsAccessRequest
import com.google.android.play.agesignals.AgeSignalsManagerFactory
import com.google.android.play.agesignals.AgeSignalsRequest
import com.google.android.play.agesignals.model.AgeSignalsStatus
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "com.decideforus.app/age_signals"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method != "checkAgeSignals") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
                    result.success(mapOf("status" to "unsupported"))
                    return@setMethodCallHandler
                }

                checkAgeSignals(result)
            }
    }

    private fun checkAgeSignals(channelResult: MethodChannel.Result) {
        val manager = AgeSignalsManagerFactory.create(applicationContext)
        val accessRequest = AgeSignalsAccessRequest.builder()
            .setActivity(this)
            .build()

        manager.requestAgeSignalsAccess(accessRequest)
            .addOnSuccessListener { accessResult ->
                when (accessResult.ageSignalsStatus()) {
                    AgeSignalsStatus.SHARED -> {
                        manager.checkAgeSignals(AgeSignalsRequest.builder().build())
                            .addOnSuccessListener { signals ->
                                // Return only the values needed for this in-memory check. Do not
                                // log or persist age signals, install IDs, or approval dates.
                                channelResult.success(
                                    mapOf(
                                        "status" to "shared",
                                        "ageLower" to signals.ageLower(),
                                        "ageUpper" to signals.ageUpper(),
                                    ),
                                )
                            }
                            .addOnFailureListener { error ->
                                channelResult.error(
                                    "AGE_SIGNALS_CHECK_FAILED",
                                    error.message,
                                    null,
                                )
                            }
                    }

                    AgeSignalsStatus.VERIFICATION_REQUIRED ->
                        channelResult.success(mapOf("status" to "verificationRequired"))

                    else -> channelResult.success(mapOf("status" to "notShared"))
                }
            }
            .addOnFailureListener { error ->
                channelResult.error("AGE_SIGNALS_ACCESS_FAILED", error.message, null)
            }
    }
}
