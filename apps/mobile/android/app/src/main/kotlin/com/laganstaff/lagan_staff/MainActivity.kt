package com.laganstaff.lagan_staff

import android.net.Uri
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "laganstaff/document").setMethodCallHandler { call, result ->
            val path = call.arguments as? String
            if (call.method != "readText" || path == null) {
                result.notImplemented()
                return@setMethodCallHandler
            }
            try {
                val image = InputImage.fromFilePath(this, Uri.fromFile(File(path)))
                val reader = TextRecognition.getClient(DevanagariTextRecognizerOptions.Builder().build())
                reader.process(image)
                    .addOnSuccessListener { result.success(it.text) }
                    .addOnFailureListener { result.error("ocr", "Could not read document", null) }
                    .addOnCompleteListener { reader.close() }
            } catch (error: Exception) {
                result.error("image", "Could not open document", null)
            }
        }
    }
}
