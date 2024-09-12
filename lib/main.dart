import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For decoding JSON
import 'package:image_downloader/image_downloader.dart';
import 'package:wallpaper_manager_flutter/wallpaper_manager_flutter.dart';

// Unsplash API Key (replace with your actual key)
const String apiKey = 'YOUR_UNSPLASH_API_KEY';
const String unsplashUrl = 'https://api.unsplash.com/photos/?client_id=$apiKey';

void main() {
  runApp(WallpaperApp());
}

class WallpaperApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wallpaper App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: WallpaperHomePage(),
    );
  }
}

class WallpaperHomePage extends StatefulWidget {
  @override
  _WallpaperHomePageState createState() => _WallpaperHomePageState();
}

class _WallpaperHomePageState extends State<WallpaperHomePage> {
  List<String> imageUrls = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchWallpapers();
  }

  // Fetch Wallpapers from Unsplash
  Future<void> fetchWallpapers() async {
    try {
      final response = await http.get(Uri.parse(unsplashUrl));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          imageUrls = data.map((item) => item['urls']['full']).toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load images');
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Wallpaper App')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Carousel Slider
          CarouselSlider(
            options: CarouselOptions(
              height: 400.0,
              enlargeCenterPage: true,
              autoPlay: true,
            ),
            items: imageUrls.map((url) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullScreenImage(url: url),
                    ),
                  );
                },
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 5.0),
                  child: Image.network(url, fit: BoxFit.cover),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class FullScreenImage extends StatelessWidget {
  final String url;
  FullScreenImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Wallpaper View'),
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: () {
              downloadImage(url);
            },
          ),
          IconButton(
            icon: Icon(Icons.wallpaper),
            onPressed: () {
              setWallpaper(url);
            },
          ),
        ],
      ),
      body: Center(
        child: Image.network(url, fit: BoxFit.cover, width: double.infinity),
      ),
    );
  }

  // Download the image
  Future<void> downloadImage(String url) async {
    try {
      await ImageDownloader.downloadImage(url);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Image Downloaded')));
    } catch (e) {
      print('Failed to download image: $e');
    }
  }

  // Set the image as wallpaper
  Future<void> setWallpaper(String url) async {
    try {
      int location = WallpaperManagerFlutter.HOME_SCREEN;
      var file = await ImageDownloader.downloadImage(url);
      await WallpaperManagerFlutter().setWallpaperFromFile(file!, location);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Wallpaper Set')));
    } catch (e) {
      print('Failed to set wallpaper: $e');
    }
  }
}
