# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.kts.

# Keep Kotlin Serialization
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.AnnotationsKt

-keepclassmembers class kotlinx.serialization.json.** {
    *** Companion;
}
-keepclasseswithmembers class kotlinx.serialization.json.** {
    kotlinx.serialization.KSerializer serializer(...);
}

-keep,includedescriptorclasses class com.roadrank.app.**$$serializer { *; }
-keepclassmembers class com.roadrank.app.** {
    *** Companion;
}
-keepclasseswithmembers class com.roadrank.app.** {
    kotlinx.serialization.KSerializer serializer(...);
}

# Keep data classes for JSON parsing
-keep class com.roadrank.app.data.** { *; }
