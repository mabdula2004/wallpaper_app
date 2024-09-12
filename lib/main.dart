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
      theme: ThemeData.dark(), // Apply dark theme
      home: CategoryScreen(),
    );
  }
}

class CategoryScreen extends StatefulWidget {
  @override
  _CategoryScreenState createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final String apiKey = 'nldNE4K8VlngtRXcqSlkaAJ1n9QXtWQq3deB0RoJKM6NpH6GlyN8IIFS';  // Pexels API key
  final List<Map<String, String>> categories = [
    {'name': 'Nature', 'query': 'nature'},
    {'name': 'Cars', 'query': 'cars'},
    {'name': 'Animals', 'query': 'animals'},
    {'name': 'Cities', 'query': 'city'},
  ];

  Map<String, String> categoryImages = {}; // Store category images
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCategoryImages();  // Fetch category images on app start
  }

  Future<void> fetchCategoryImages() async {
    for (var category in categories) {
      final String query = category['query']!;
      final String apiUrl = 'https://api.pexels.com/v1/search?query=$query&per_page=1';

      try {
        final response = await http.get(Uri.parse(apiUrl), headers: {
          'Authorization': apiKey,
        });
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          setState(() {
            categoryImages[query] = data['photos'][0]['src']['medium'];
          });
        }
      } catch (e) {
        print('Error fetching image for $query: $e');
      }
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Wallpaper Categories'),
        backgroundColor: Colors.black, // Black app bar
      ),
      backgroundColor: Colors.black, // Black background
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final imageUrl = categoryImages[category['query']!] ??
              'https://via.placeholder.com/150';  // Default image if loading

          return Card(
            color: Colors.grey[900],
            margin: EdgeInsets.all(10),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WallpaperCarousel(category: category['query']!),
                  ),
                );
              },
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      category['name']!,
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ),
                  Image.network(
                    imageUrl,
                    height: 150,  // Adjust the height of the image here
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  SizedBox(height: 10),
                ],
              ),
            ),
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
  final String apiKey = 'nldNE4K8VlngtRXcqSlkaAJ1n9QXtWQq3deB0RoJKM6NpH6GlyN8IIFS';  // Pexels API key

  @override
  void initState() {
    super.initState();
    fetchImages();
  }

  Future<void> fetchImages() async {
    final String apiUrl = 'https://api.pexels.com/v1/search?query=${widget.category}&per_page=10';

    try {
      final response = await http.get(Uri.parse(apiUrl), headers: {
        'Authorization': apiKey,
      });
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
      appBar: AppBar(
        title: Text('${widget.category} Wallpapers'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : hasError
          ? Center(
        child: Text(
          'Error loading wallpapers. Please try again later.',
          style: TextStyle(color: Colors.white),
        ),
      )
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
