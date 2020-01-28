import 'dart:math';

import 'package:flutter/material.dart';
import 'package:step_bpm/main.dart';
import 'package:youtube_api/youtube_api.dart';
import 'package:url_launcher/url_launcher.dart';

import 'sql.dart';

class YTResults extends StatefulWidget {
  final Data data;
  YTResults(this.data);

  @override
  YTResultState createState() => new YTResultState();
}

class YTResultState extends State<YTResults> {
  SongDatabase db = new SongDatabase();

  static String key = "YTKEY";
  YoutubeAPI ytApi = new YoutubeAPI(key);

  List<YT_API> ytResult = [];
  String query = "";
  String url = "";

  callAPI(int bpm) async {
    print('UI callled');
    List<SongData> songs = await db.search(bpm);

    if (songs.isEmpty) {
      query = "\t$bpm bpm song";
    } else {
      int rng = new Random().nextInt(songs.length);
      SongData selected = songs.elementAt(rng);
      query = "\t${selected.title} \t${selected.artist}";
    }

    ytResult = await ytApi.search(query);
    setState(() {
      print('UI Updated');
    });
  }

  Future<List<SongData>> getSongs(bpm) async {
    List<SongData> songs = await db.search(bpm);
    return songs;
  }

  @override
  void initState() {
    super.initState();
    callAPI(widget.data.bpm);
    print('API was called');
  }

  _launchURL() async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      theme: Theme.of(context),
      home: new Scaffold(
          appBar: new AppBar(
            title: Text("A song with\t${widget.data.bpm} bpm"),
            leading: IconButton(icon:Icon(Icons.arrow_back),
              onPressed:() => Navigator.pop(context),
            )
          ),
          body: new Container(
            child: ListView.builder(
                itemCount: ytResult.length,
                itemBuilder: (_, int index) => listItem(index)
            ),
          ),
      ),
    );
  }
  Widget listItem(index){
    return new GestureDetector(
      onTap: () {
        url = "${ytResult[index].url.replaceAll(new RegExp(r"\s+\b|\b\s"), "")}";
        _launchURL();
      },
      child: new Card(
        child: new Container(
          margin: EdgeInsets.symmetric(vertical: 7.0),
          padding: EdgeInsets.all(12.0),
          child:new Row(
            children: <Widget>[
              new Image.network(ytResult[index].thumbnail['default']['url'],),
              new Padding(padding: EdgeInsets.only(right: 20.0)),
              new Expanded(child: new Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    new Text(
                      ytResult[index].title.replaceAll("&#39;", "'"),
                      softWrap: true,
                      style: TextStyle(fontSize:18.0),
                    ),
                    new Padding(padding: EdgeInsets.only(bottom: 1.5)),
                    new Text(
                      ytResult[index].channelTitle.replaceAll("&#39;", "'"),
                      softWrap: true,
                    ),
                    new Padding(padding: EdgeInsets.only(bottom: 3.0)),
                    new Text(
                      ytResult[index].url,
                      softWrap: true,
                    ),
                  ]
                )
              )
            ],
          ),
        ),
      )
    );
  }
}