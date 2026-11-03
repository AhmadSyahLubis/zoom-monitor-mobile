package com.ptpn4.zoom_monitor_mobile

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyInfo
import android.security.keystore.KeyProperties
import android.util.Base64
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.KeyFactory
import java.security.PrivateKey
import java.security.Signature
import java.security.spec.ECGenParameterSpec

class MainActivity : FlutterFragmentActivity() {
    private val alias = "zoom_monitor_biometric_v2"
    private var pending: MethodChannel.Result? = null
    private var prompt: BiometricPrompt? = null
    private fun store(): KeyStore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "zoom_monitor/device_biometrics_v2").setMethodCallHandler { call, result ->
            if (pending != null) { result.error("BUSY", "Verifikasi sedang berlangsung", null); return@setMethodCallHandler }
            try {
                when (call.method) {
                    "hasKey" -> result.success(store().containsAlias(alias))
                    "deleteKey" -> { store().deleteEntry(alias); result.success(null) }
                    "createKey" -> {
                        check(BiometricManager.from(this).canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_STRONG) == BiometricManager.BIOMETRIC_SUCCESS)
                        store().deleteEntry(alias)
                        val spec = KeyGenParameterSpec.Builder(alias, KeyProperties.PURPOSE_SIGN or KeyProperties.PURPOSE_VERIFY)
                            .setAlgorithmParameterSpec(ECGenParameterSpec("secp256r1"))
                            .setDigests(KeyProperties.DIGEST_SHA256)
                            .setUserAuthenticationRequired(true)
                        if (Build.VERSION.SDK_INT >= 24) spec.setInvalidatedByBiometricEnrollment(true)
                        if (Build.VERSION.SDK_INT >= 30) spec.setUserAuthenticationParameters(0, KeyProperties.AUTH_BIOMETRIC_STRONG)
                        else { @Suppress("DEPRECATION") spec.setUserAuthenticationValidityDurationSeconds(-1) }
                        val generator = KeyPairGenerator.getInstance(KeyProperties.KEY_ALGORITHM_EC, "AndroidKeyStore")
                        generator.initialize(spec.build())
                        val key = generator.generateKeyPair()
                        val info = KeyFactory.getInstance(key.private.algorithm, "AndroidKeyStore").getKeySpec(key.private, KeyInfo::class.java)
                        @Suppress("DEPRECATION")
                        if (!info.isInsideSecureHardware) { store().deleteEntry(alias); error("Hardware key storage unavailable") }
                        result.success(Base64.encodeToString(key.public.encoded, Base64.NO_WRAP))
                    }
                    "sign" -> {
                        val challenge = call.argument<String>("challenge") ?: error("Challenge required")
                        check(challenge.isNotEmpty() && challenge.length <= 1024)
                        val key = store().getKey(alias, null) as PrivateKey
                        val signature = Signature.getInstance("SHA256withECDSA").apply { initSign(key) }
                        pending = result
                        prompt = BiometricPrompt(this, ContextCompat.getMainExecutor(this), object : BiometricPrompt.AuthenticationCallback() {
                            override fun onAuthenticationError(code: Int, message: CharSequence) {
                                pending?.error("BIOMETRIC_CANCELLED", "Verifikasi biometrik dibatalkan atau tidak tersedia", null)
                                pending = null
                            }
                            override fun onAuthenticationSucceeded(auth: BiometricPrompt.AuthenticationResult) {
                                val reply = pending ?: return
                                pending = null
                                try {
                                    val signer = auth.cryptoObject?.signature ?: error("Authenticated signature required")
                                    signer.update(challenge.toByteArray(Charsets.UTF_8))
                                    reply.success(Base64.encodeToString(signer.sign(), Base64.NO_WRAP))
                                } catch (_: Exception) { reply.error("SIGN_FAILED", "Kunci perangkat tidak dapat digunakan. Daftarkan ulang melalui password.", null) }
                            }
                        })
                        val info = BiometricPrompt.PromptInfo.Builder().setTitle("Verifikasi Zoom Monitor")
                            .setSubtitle("Gunakan biometrik perangkat untuk melanjutkan")
                            .setAllowedAuthenticators(BiometricManager.Authenticators.BIOMETRIC_STRONG)
                            .setNegativeButtonText("Batal").build()
                        prompt!!.authenticate(info, BiometricPrompt.CryptoObject(signature))
                    }
                    else -> result.notImplemented()
                }
            } catch (_: Exception) {
                pending = null
                result.error("BIOMETRIC_UNAVAILABLE", "Biometrik aman tidak tersedia. Gunakan password atau daftarkan ulang perangkat.", null)
            }
        }
    }
}
