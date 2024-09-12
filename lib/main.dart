import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_downloader/image_downloader.dart';
import 'package:wallpaper_manager_flutter/wallpaper_manager_flutter.dart';

// Pexels API Key
const String apiKey = 'nldNE4K8VlngtRXcqSlkaAJ1n9QXtWQq3deB0RoJKM6NpH6GlyN8IIFS';
const String pexelsBaseUrl = 'https://api.pexels.com/v1/search';
const Map<String, String> categories = {
  'Nature': 'nature',
  'Abstract': 'abstract',
  'Animals': 'animals',
  'City': 'city',
  'Cars': 'cars',
};

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
  String selectedCategory = 'Nature'; // Default category
  List<String> imageUrls = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchWallpapers(); // Fetch default category wallpapers
  }

  // Fetch Wallpapers from Pexels based on category
  Future<void> fetchWallpapers() async {
    setState(() {
      isLoading = true;
    });
    final String url =
        '$pexelsBaseUrl?query=$selectedCategory&per_page=15';
    try {
      final response = await http.get(Uri.parse(url), headers: {
        'Authorization': apiKey,
      });
      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          imageUrls = (data['photos'] as List)
              .map((item) => item['src']['large2x'] as String)
              .toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load images');
      }
    } catch (e) {
      print(e);
      setState(() {
        isLoading = false;
      });
    }
  }

  // Handle category change
  void onCategoryChange(String? category) {
    setState(() {
      selectedCategory = category!;
    });
    fetchWallpapers(); // Fetch wallpapers for the selected category
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Wallpaper App')),
      body: Column(
        children: [
          // Category Dropdown
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: selectedCategory,
              items: categories.keys
                  .map((String category) => DropdownMenuItem<String>(
                value: category,
                child: Text(category),
              ))
                  .toList(),
              onChanged: onCategoryChange,
            ),
          ),
          Expanded(
            child: isLoading
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
                            builder: (context) =>
                                FullScreenImage(url: url),
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
