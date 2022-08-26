import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

const String baseUrl = 'https://hacker-news.firebaseio.com/v0/';
const String baseItemUrl = 'https://hacker-news.firebaseio.com/v0/item/';
const String topStories = 'topstories.json';

Future<List> requestTopStories() async {
  final response = await http.get(Uri.parse('$baseUrl/$topStories'));
  if (response.statusCode == 200) {
    final bodyList = jsonDecode(response.body);
    return bodyList.sublist(25);
  } else {
    throw Exception('Failed to load');
  }
}

Future<List> populateStories() async {
  List<Story> stories = [];
  final idList = await requestTopStories();
  for (var story in idList) {
    String storyString = story.toString();
    if (stories.length < 20) {
      final storyResponse =
          await http.get(Uri.parse('$baseItemUrl$storyString.json'));
      if (storyResponse.statusCode == 200) {
        stories.add(Story.fromJson(jsonDecode(storyResponse.body)));
      } else {
        throw Exception('storyResponse');
      }
    }
  }

  if (stories.isNotEmpty) {
    return stories;
  } else {
    throw Exception('stories is null');
  }
}

class Story {
  final String by;
  final int? descendants;
  final int id;
  final List? kids;
  final int? score;
  final int? time;
  final String title;
  final String type;
  final String? url;

  Story(
      {required this.by,
      required this.descendants,
      required this.id,
      required this.kids,
      required this.score,
      required this.time,
      required this.title,
      required this.type,
      required this.url});

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      by: json['by'],
      descendants: json['descendants'],
      id: json['id'],
      kids: json['kids'],
      score: json['score'],
      time: json['time'],
      title: json['title'],
      type: json['type'],
      url: json['url'],
    );
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<List> storyItems;

  @override
  void initState() {
    super.initState();
    storyItems = populateStories();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SimpleHN',
      theme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('simple hackernews demo'),
        ),
        body: Center(
          child: FutureBuilder(
              future: storyItems,
              builder: (BuildContext context, AsyncSnapshot<List> snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return ListView.builder(
                      itemCount: snapshot.data?.length,
                      itemBuilder: (context, index) {
                        Story story = snapshot.data?[index];
                        return Card(
                          child: InkWell(
                            child: ListTile(
                              title: Text(story.title),
                              subtitle: Text('posted by: ${story.by}'),
                            ),
                            onTap: () {
                              launchUrl(Uri.parse(
                                  story.url ?? 'https://news.ycombinator.com'));
                            },
                          ),
                        );
                      });
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              }),
        ),
      ),
    );
  }
}
