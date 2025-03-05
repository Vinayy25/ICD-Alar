# Razorpay required rules
-keepattributes *Annotation*
-dontwarn com.razorpay.**
-keep class com.razorpay.** {*;}
-optimizations !method/inlining/
-keepclasseswithmembers class * {
  public void onPayment*(...);
}

# Fix for missing proguard.annotation.Keep classes
-dontwarn proguard.annotation.Keep
-dontwarn proguard.annotation.KeepClassMembers