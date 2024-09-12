import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(WallpaperApp());
}

class WallpaperApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wallpaper App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CategoryScreen(),
    );
  }
}

class CategoryScreen extends StatelessWidget {
  final List<String> categories = ['Nature', 'Cars', 'Animals', 'Cities'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Wallpaper Categories')),
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(categories[index]),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WallpaperCarousel(category: categories[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class WallpaperCarousel extends StatefulWidget {
  final String category;
  WallpaperCarousel({required this.category});

  @override
  _WallpaperCarouselState createState() => _WallpaperCarouselState();
}

class _WallpaperCarouselState extends State<WallpaperCarousel> {
  List<String> imageUrls = [];
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    fetchImages();
  }

  Future<void> fetchImages() async {
    final String apiKey = 'nldNE4K8VlngtRXcqSlkaAJ1n9QXtWQq3deB0RoJKM6NpH6GlyN8IIFS';  // Your Pexels API key
    final String category = widget.category;
    final String apiUrl = 'https://api.pexels.com/v1/search?query=$category&per_page=10';

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': apiKey,  // Add API key in headers
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          imageUrls = List<String>.from(data['photos'].map((photo) => photo['src']['medium']));
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load wallpapers');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
        print('Error fetching images: $e');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.category} Wallpapers')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : hasError
          ? Center(child: Text('Error loading wallpapers. Please try again later.'))
          : CarouselSlider(
        options: CarouselOptions(height: 400.0, autoPlay: true),
        items: imageUrls.map((url) {
          return Builder(
            builder: (BuildContext context) {
              return Container(
                width: MediaQuery.of(context).size.width,
                margin: EdgeInsets.symmetric(horizontal: 5.0),
                child: Image.network(url, fit: BoxFit.cover),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}
