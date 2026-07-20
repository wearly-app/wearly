package com.wearly.wearly

import android.annotation.SuppressLint
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.util.Base64
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import java.security.MessageDigest

class MainActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (BuildConfig.DEBUG) {
            Log.d("KakaoKeyHash", "Kakao KeyHash: ${getKeyHash(this)}")
        }
    }

    private fun getKeyHash(context: Context): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            val packageInfo = context.packageManager
                .getPackageInfo(context.packageName, PackageManager.GET_SIGNING_CERTIFICATES)
            val signatures = packageInfo.signingInfo?.signingCertificateHistory ?: arrayOf()

            for (signature in signatures) {
                val messageDigest = MessageDigest.getInstance("SHA")
                messageDigest.update(signature.toByteArray())
                return Base64.encodeToString(messageDigest.digest(), Base64.NO_WRAP)
            }
            throw IllegalStateException()
        }

        return getKeyHashDeprecated(context)
    }

    @Suppress("DEPRECATION")
    @SuppressLint("PackageManagerGetSignatures")
    private fun getKeyHashDeprecated(context: Context): String {
        val packageInfo = context.packageManager
            .getPackageInfo(context.packageName, PackageManager.GET_SIGNATURES)

        for (signature in packageInfo.signatures ?: arrayOf()) {
            val messageDigest = MessageDigest.getInstance("SHA")
            messageDigest.update(signature.toByteArray())
            return Base64.encodeToString(messageDigest.digest(), Base64.NO_WRAP)
        }
        throw IllegalStateException()
    }
}
