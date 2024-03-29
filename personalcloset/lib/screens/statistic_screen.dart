import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class StatisticsPage extends StatefulWidget {
  @override
  _StatisticsPageState createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  List<Map<String, dynamic>> statistics = [];

  @override
  void initState() {
    super.initState();
    fetchStatisticsData();
  }

  Future<void> fetchStatisticsData() async {
    try {
      // Firestore에서 월간 통계 데이터 가져오기
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('images').get();

      List<Map<String, dynamic>> tempStatistics = [];

      for (var doc in querySnapshot.docs) {
        Map<String, dynamic>? data = doc.data()
            as Map<String, dynamic>?; // 명시적으로 Map<String, dynamic>으로 캐스트
        if (data != null &&
            data['imageUrl'] != null &&
            data['date'] != null &&
            data['items'] != null) {
          String? imageUrl = data['imageUrl'] as String?; // String으로 변환
          String? date = data['date'] as String?; // String으로 변환
          Iterable<dynamic>? items =
              data['items'] as Iterable<dynamic>?; // Iterable<dynamic>으로 변환

          if (imageUrl != null && date != null && items != null) {
            List<String> itemList = items
                .map((dynamic item) => item.toString())
                .toList(); // 각 항목을 명시적으로 String으로 캐스트
            tempStatistics.add({
              'imageUrl': imageUrl,
              'date': date,
              'items': itemList,
            });
          }
        }
      }

      setState(() {
        statistics = tempStatistics;
      });
    } catch (e) {
      print('통계 데이터를 가져오지 못했습니다: $e');
    }
  }

  List<Map<String, dynamic>> calculateMonthlyStatistics() {
    // 통계를 계산하는 로직을 구현
    // 'statistics' 목록을 기반으로 결과를 반환

    // 예: 항목 빈도 계산
    Map<String, int> itemFrequency = {};
    for (var data in statistics) {
      List<String>? items = data['items']; // List<String>으로 변환
      if (items != null) {
        for (var item in items) {
          itemFrequency[item] = (itemFrequency[item] ?? 0) + 1;
        }
      }
    }

    // 통계 데이터 정렬
    List<MapEntry<String, int>> sortedEntries = itemFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // 정렬된 데이터 반환
    List<Map<String, dynamic>> monthlyStatistics = sortedEntries
        .map((entry) => {
              'item': entry.key,
              'frequency': entry.value,
            })
        .toList();

    return monthlyStatistics;
  }

  List<Map<String, dynamic>> calculateMonthlyStatisticsLowToHigh() {
    // 통계를 계산하는 로직을 구현
    // 'statistics' 목록을 기반으로 결과를 반환
    // 이 버전은 빈도수가 낮은 순서로 정렬됩니다.

    Map<String, int> itemFrequency = {};
    for (var data in statistics) {
      List<String>? items = data['items']; // List<String>으로 변환
      if (items != null) {
        for (var item in items) {
          itemFrequency[item] = (itemFrequency[item] ?? 0) + 1;
        }
      }
    }

    // 통계 데이터를 빈도수가 낮은 순서로 정렬
    List<MapEntry<String, int>> sortedEntries = itemFrequency.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    // 정렬된 데이터 반환
    List<Map<String, dynamic>> monthlyStatistics = sortedEntries
        .map((entry) => {
              'item': entry.key,
              'frequency': entry.value,
            })
        .toList();

    return monthlyStatistics;
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> monthlyStatisticsHighToLow =
        calculateMonthlyStatistics();
    List<Map<String, dynamic>> monthlyStatisticsLowToHigh =
        calculateMonthlyStatisticsLowToHigh();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(' 통계'),
          bottom: TabBar(
            tabs: [
              Tab(text: '가장 자주 입은 옷들'),
              Tab(text: '손이 가지 않았던 옷'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // 빈도가 높은 순의 통계를 표시
            ListView.builder(
              itemCount: monthlyStatisticsHighToLow.length,
              itemBuilder: (BuildContext context, int index) {
                Map<String, dynamic> statistic =
                    monthlyStatisticsHighToLow[index];
                String item = statistic['item'];
                int frequency = statistic['frequency'];
                String? imageUrl = statistic['imageUrl'];

                return ListTile(
                  leading: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          width: 80,
                          height: 80,
                        )
                      : FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('shopping_list')
                              .doc(
                                  'placeholder_category') // 실제 selectedCategory 값으로 대체
                              .collection('items')
                              .doc(item)
                              .get(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return CircularProgressIndicator();
                            } else if (snapshot.hasError) {
                              return Icon(Icons.error);
                            } else {
                              if (snapshot.data != null &&
                                  snapshot.data!.exists) {
                                Map<String, dynamic>? data =
                                    snapshot.data!.data() as Map<String,
                                        dynamic>?; // 명시적으로 Map<String, dynamic>으로 캐스트
                                String? imageUrl = data?['imageUrl'];
                                if (imageUrl != null) {
                                  return Image.network(
                                    imageUrl,
                                    width: 80,
                                    height: 80,
                                  );
                                }
                              }
                              return Icon(Icons.image_not_supported);
                            }
                          },
                        ),
                  title: Text(item),
                  subtitle: Text('착용 빈도: $frequency'),
                );
              },
            ),

            // 빈도가 낮은 순의 통계를 표시
            ListView.builder(
              itemCount: monthlyStatisticsLowToHigh.length,
              itemBuilder: (BuildContext context, int index) {
                Map<String, dynamic> statistic =
                    monthlyStatisticsLowToHigh[index];
                String item = statistic['item'];
                int frequency = statistic['frequency'];
                String? imageUrl = statistic['imageUrl'];

                return ListTile(
                  leading: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          width: 80,
                          height: 80,
                        )
                      : FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('shopping_list')
                              .doc(
                                  'placeholder_category') // 실제 selectedCategory 값으로 대체
                              .collection('items')
                              .doc(item)
                              .get(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return CircularProgressIndicator();
                            } else if (snapshot.hasError) {
                              return Icon(Icons.error);
                            } else {
                              if (snapshot.data != null &&
                                  snapshot.data!.exists) {
                                Map<String, dynamic>? data =
                                    snapshot.data!.data() as Map<String,
                                        dynamic>?; // 명시적으로 Map<String, dynamic>으로 캐스트
                                String? imageUrl = data?['imageUrl'];
                                if (imageUrl != null) {
                                  return Image.network(
                                    imageUrl,
                                    width: 80,
                                    height: 80,
                                  );
                                }
                              }
                              return Icon(Icons.image_not_supported);
                            }
                          },
                        ),
                  title: Text(item),
                  subtitle: Text('착용 빈도: $frequency'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
