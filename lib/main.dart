import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HallMate',
      theme: ThemeData.dark(),
      home: const HallWebView(),
    );
  }
}

class HallWebView extends StatefulWidget {
  const HallWebView({super.key});

  @override
  State<HallWebView> createState() => _HallWebViewState();
}

class _HallWebViewState extends State<HallWebView> {

  late final WebViewController controller;

  double progress = 0;

  @override
  void initState() {
    super.initState();

    controller = WebViewController()

      ..setJavaScriptMode(JavaScriptMode.unrestricted)

      ..setBackgroundColor(const Color(0xFF000000))

      ..setNavigationDelegate(
        NavigationDelegate(

          onProgress: (int p) {
            setState(() {
              progress = p / 100;
            });
          },

          onPageFinished: (String url) async {

            // Targeted fix for the Tutorial Video Popup
            await controller.runJavaScript(r"""
              (function() {
                // 1. Tell the website we've already seen the tutorial 
                // This prevents the automatic popup logic from triggering.
                sessionStorage.setItem("hasSeenTutorial", "true");

                // 2. Safety: If a video is already playing, stop it
                function stopAutoplay() {
                  document.querySelectorAll('video').forEach(function(v) {
                    if (v.autoplay) {
                      v.pause();
                      v.autoplay = false;
                      v.removeAttribute('autoplay');
                    }
                  });
                  
                  // Hide any modal that might have already popped up
                  document.querySelectorAll('[role="dialog"]').forEach(function(modal) {
                    if (modal.innerText.includes("Tutorial") || modal.querySelector('video')) {
                       // Try to find and click the close button if it exists
                       var closeBtn = modal.querySelector('button');
                       if (closeBtn) closeBtn.click();
                       modal.style.display = 'none';
                    }
                  });
                }

                // Run immediately and after a short delay to be sure
                stopAutoplay();
                setTimeout(stopAutoplay, 500);
                setTimeout(stopAutoplay, 1500);
              })();
            """);

            // Optional dark background
            await controller.runJavaScript("""
              document.body.style.backgroundColor = "#000000";
            """);
          },
        ),
      )

      ..loadRequest(
        Uri.parse("https://hall.baust.edu.bd/login"),
      );

    // Android specific settings
    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(true);
    }
  }

  Future<bool> _goBack() async {

    if (await controller.canGoBack()) {

      await controller.goBack();

      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {

    return WillPopScope(

      onWillPop: _goBack,

      child: Scaffold(

        body: SafeArea(

          child: Stack(

            children: [

              WebViewWidget(
                controller: controller,
              ),

              if (progress < 1)

                LinearProgressIndicator(
                  value: progress,
                  minHeight: 3,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
