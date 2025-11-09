import 'package:flutter/material.dart';
import 'package:testing_flutter/components/superwrapperstryles/superwrapper.dart';

class NewsletterFeedScreen extends StatefulWidget {
  const NewsletterFeedScreen({Key? key}) : super(key: key);

  @override
  State<NewsletterFeedScreen> createState() => _NewsletterFeedScreenState();
}

class _NewsletterFeedScreenState extends State<NewsletterFeedScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedTabIndex = 1; // Technology tab selected

  final List<String> _tabs = [
    'Home',
    'Technology',
    'Art & Illustration',
    'Health',
    'Politics',
  ];

  final List<Map<String, dynamic>> _newsletters = [
    {
      'rank': 1,
      'title': 'The Pragmatic Engineer',
      'author': 'Gergely Orosz',
      'iconColor': const Color(0xFFE57373),
      'isSubscribed': true,
    },
    {
      'rank': 2,
      'title': 'ByteByteGo Newsletter',
      'author': 'Alex Xu',
      'iconColor': const Color(0xFF81C784),
      'isSubscribed': false,
    },
    {
      'rank': 3,
      'title': 'Chamath Palihapitiya',
      'author': 'Chamath Palihapitiya',
      'iconColor': const Color(0xFF9E9E9E),
      'isSubscribed': false,
    },
    {
      'rank': 4,
      'title': 'Fabricated Knowledge',
      'author': 'Doug OLaughlin',
      'iconColor': const Color(0xFF424242),
      'isSubscribed': false,
    },
    {
      'rank': 5,
      'title': 'Computer, Enhance!',
      'author': 'Casey Muratori',
      'iconColor': const Color(0xFF64B5F6),
      'isSubscribed': false,
    },
    {
      'rank': 6,
      'title': 'Exponential View',
      'author': 'Azeem Azhar',
      'iconColor': const Color(0xFF81C784),
      'isSubscribed': false,
    },
  ];

  Widget _buildCustomSearchField(BuildContext context) {
    return Expanded(
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 12),
              child: Icon(Icons.search, color: Colors.grey, size: 18),
            ),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: KCustomTextStyle.kRegular(
                  context,
                  FontSize.kMedium,
                  Colors.black,
                  KConstantFonts.haskoyMedium,
                ),
                decoration: InputDecoration(
                  hintText: 'Search',
                  hintStyle: KCustomTextStyle.kRegular(
                    context,
                    FontSize.kMedium,
                    Colors.grey,
                    KConstantFonts.haskoyMedium,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return Container(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _tabs.length,
        itemBuilder: (context, index) {
          final isSelected = index == _selectedTabIndex;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedTabIndex = index;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.grey[200] : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  _tabs[index],
                  style: KCustomTextStyle.kMedium(
                    context,
                    FontSize.kMedium,
                    isSelected ? Colors.black : Colors.grey,
                    KConstantFonts.haskoyMedium,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNewsletterTile(
    BuildContext context,
    Map<String, dynamic> newsletter,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // Rank
          Container(
            width: 24,
            child: Text(
              newsletter['rank'].toString(),
              style: KCustomTextStyle.kBold(
                context,
                FontSize.kMedium,
                Colors.black,
                KConstantFonts.haskoyMedium,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: newsletter['iconColor'],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.bar_chart, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  newsletter['title'],
                  style: KCustomTextStyle.kMedium(
                    context,
                    FontSize.kMedium,
                    Colors.black,
                    KConstantFonts.haskoyMedium,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  newsletter['author'],
                  style: KCustomTextStyle.kRegular(
                    context,
                    FontSize.kMedium,
                    Colors.grey,
                    KConstantFonts.haskoyMedium,
                  ),
                ),
              ],
            ),
          ),

          // Subscribe Button or Check
          if (newsletter['isSubscribed'])
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 16),
            )
          else
            GestureDetector(
              onTap: () {
                setState(() {
                  newsletter['isSubscribed'] = true;
                });
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF6B35),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 20),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCommentSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Colors.grey,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Taylor Lorenz',
                        style: KCustomTextStyle.kMedium(
                          context,
                          FontSize.kMedium,
                          Colors.black,
                          KConstantFonts.haskoyMedium,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF6B35),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 10,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'User Mag • Subscribe',
                    style: KCustomTextStyle.kRegular(
                      context,
                      FontSize.kMedium,
                      Colors.grey,
                      KConstantFonts.haskoyMedium,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                '1d',
                style: KCustomTextStyle.kRegular(
                  context,
                  FontSize.kMedium,
                  Colors.grey,
                  KConstantFonts.haskoyMedium,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.more_horiz, color: Colors.grey, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'This is interesting and I can def see Substack getting an influx of AI generated content, but I\'m skeptical any of these "AI detection" tools are that good. I tried one of them on my book (obviously written fu... See more',
            style: KCustomTextStyle.kRegular(
              context,
              FontSize.kMedium,
              Colors.black,
              KConstantFonts.haskoyMedium,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Colors.grey,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 12),
              ),
              const SizedBox(width: 8),
              Text(
                'Judd Legum',
                style: KCustomTextStyle.kRegular(
                  context,
                  FontSize.kMedium,
                  Colors.grey,
                  KConstantFonts.haskoyMedium,
                ),
              ),
              const Spacer(),
              Text(
                '2d',
                style: KCustomTextStyle.kRegular(
                  context,
                  FontSize.kMedium,
                  Colors.grey,
                  KConstantFonts.haskoyMedium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B35),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.bookmark,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildCustomSearchField(context),
                  const SizedBox(width: 16),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Colors.grey,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildTabBar(context),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Top in Technology Header
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Top in Technology',
                            style: KCustomTextStyle.kBold(
                              context,
                              FontSize.kMedium,
                              Colors.black,
                              KConstantFonts.haskoyMedium,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.grey,
                            size: 16,
                          ),
                        ],
                      ),
                    ),

                    // Newsletter List
                    Container(
                      color: Colors.white,
                      child: Column(
                        children: _newsletters
                            .map(
                              (newsletter) =>
                                  _buildNewsletterTile(context, newsletter),
                            )
                            .toList(),
                      ),
                    ),

                    // Comment Section
                    _buildCommentSection(context),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Bottom Navigation
      bottomNavigationBar: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const Icon(Icons.home, color: Colors.black),
            const Icon(Icons.folder, color: Colors.grey),
            const Icon(Icons.play_circle, color: Colors.grey),
            const Icon(Icons.chat_bubble, color: Colors.grey),
            const Icon(Icons.edit, color: Colors.grey),
          ],
        ),
      ),

      // Floating Action Button
      floatingActionButton: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          color: Color(0xFFFF6B35),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 24),
      ),
    );
  }
}
