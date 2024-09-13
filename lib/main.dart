import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'dart:io';


void main() {
  runApp(WallpaperApp());
}

class WallpaperApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Wallpaper App',
      theme: ThemeData.dark(),
      home: CategoryScreen(),
    );
  }
}

class CategoryScreen extends StatefulWidget {
  @override
  _CategoryScreenState createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final String apiKey = 'nldNE4K8VlngtRXcqSlkaAJ1n9QXtWQq3deB0RoJKM6NpH6GlyN8IIFS';
  final List<Map<String, String>> categories = [
    {'name': 'Nature', 'query': 'nature'},
    {'name': 'Cars', 'query': 'cars'},
    {'name': 'Animals', 'query': 'animals'},
    {'name': 'Cities', 'query': 'city'},
  ];

  Map<String, String> categoryImages = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCategoryImages();
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
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final imageUrl = categoryImages[category['query']!] ??
              'https://via.placeholder.com/150';

          return Card(
            color: Colors.grey[900],
            margin: EdgeInsets.all(10),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WallpaperGrid(category: category['query']!),
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      imageUrl,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
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

class WallpaperGrid extends StatefulWidget {
  final String category;
  WallpaperGrid({required this.category});

  @override
  _WallpaperGridState createState() => _WallpaperGridState();
}

class _WallpaperGridState extends State<WallpaperGrid> {
  List<String> imageUrls = [];
  bool isLoading = true;
  bool hasError = false;
  final String apiKey = 'nldNE4K8VlngtRXcqSlkaAJ1n9QXtWQq3deB0RoJKM6NpH6GlyN8IIFS';

  @override
  void initState() {
    super.initState();
    fetchImages();
  }

  Future<void> fetchImages() async {
    final String apiUrl = 'https://api.pexels.com/v1/search?query=${widget.category}&per_page=20';

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

  Future<void> downloadImage(String url) async {
    if (await Permission.storage.request().isGranted) {
      try {
        var response = await http.get(Uri.parse(url));
        var dir = await getExternalStorageDirectory();
        File file = File('${dir?.path}/${url.split('/').last}');

        await file.writeAsBytes(response.bodyBytes);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Downloaded to ${file.path}')),
        );
      } catch (e) {
        print(e);
      }
    } else {
      print('Storage permission denied');
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
          : Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.75,
          ),
          itemCount: imageUrls.length,
          itemBuilder: (context, index) {
            return Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      imageUrls[index],
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.download, color: Colors.white),
                  onPressed: () {
                    downloadImage(imageUrls[index]);
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
