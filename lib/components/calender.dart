import 'package:flutter/material.dart';
import 'package:testing_flutter/components/superwrapperstryles/superwrapper.dart';

class DateSelectionScreen extends StatefulWidget {
  const DateSelectionScreen({Key? key}) : super(key: key);

  @override
  State<DateSelectionScreen> createState() => _DateSelectionScreenState();
}

class _DateSelectionScreenState extends State<DateSelectionScreen>
    with SingleTickerProviderStateMixin {
  DateTime? startDate;
  DateTime? endDate;
  int currentMonth = 5; // May
  int currentYear = 2025;
  late AnimationController _animationController;
  late Animation<double> _animation;

  final List<String> weekDays = [
    'SUN',
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT',
  ];
  final List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  bool isDateInRange(DateTime date) {
    if (startDate == null || endDate == null) return false;
    return date.isAfter(startDate!.subtract(const Duration(days: 1))) &&
        date.isBefore(endDate!.add(const Duration(days: 1)));
  }

  bool isDateSelected(DateTime date) {
    return date.isAtSameMomentAs(startDate ?? DateTime(0)) ||
        date.isAtSameMomentAs(endDate ?? DateTime(0));
  }

  Widget _buildCalendarDay(BuildContext context, int day) {
    if (day == 0) {
      return const SizedBox(width: 40, height: 40);
    }

    final date = DateTime(currentYear, currentMonth, day);
    final isSelected = isDateSelected(date);
    final isInRange = isDateInRange(date);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (startDate == null || endDate != null) {
            startDate = date;
            endDate = null;
            _animationController.forward(from: 0);
          } else {
            if (date.isBefore(startDate!)) {
              endDate = startDate;
              startDate = date;
            } else {
              endDate = date;
            }
            _animationController.forward(from: 0);
          }
        });
      },
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected
                  ? KConstantColors.blueColor
                  : isInRange
                  ? KConstantColors.blueColor.withOpacity(
                      0.2 * _animation.value,
                    )
                  : Colors.transparent,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(
                      color: KConstantColors.blueColor,
                      width: 2 * _animation.value,
                    )
                  : null,
            ),
            child: Center(
              child: Text(
                day.toString(),
                style: KCustomTextStyle.kMedium(
                  context,
                  FontSize.kLarge,
                  isSelected
                      ? KConstantColors.whiteColor
                      : isInRange
                      ? KConstantColors.blueColor
                      : KConstantColors.blackColor,
                  KConstantFonts.haskoyMedium,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildCalendarGrid(BuildContext context) {
    List<Widget> days = [];

    // Add weekday headers
    for (String weekDay in weekDays) {
      days.add(
        Container(
          width: 40,
          height: 30,
          child: Center(
            child: Text(
              weekDay,
              style: KCustomTextStyle.kRegular(
                context,
                FontSize.kSmall,
                KConstantColors.greyColor,
                KConstantFonts.haskoyMedium,
              ),
            ),
          ),
        ),
      );
    }

    // Calculate first day of month and number of days
    DateTime firstDay = DateTime(currentYear, currentMonth, 1);
    int firstWeekday = firstDay.weekday % 7; // Convert to 0-6 where 0 is Sunday
    int daysInMonth = DateTime(currentYear, currentMonth + 1, 0).day;

    // Add empty cells for days before the first day of the month
    for (int i = 0; i < firstWeekday; i++) {
      days.add(_buildCalendarDay(context, 0));
    }

    // Add days of the month
    for (int day = 1; day <= daysInMonth; day++) {
      days.add(_buildCalendarDay(context, day));
    }

    return days;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KConstantColors.lightGreyColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header Section
            Container(
              color: KConstantColors.lightGreyColor,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.close,
                          color: KConstantColors.blackColor,
                          size: 24,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Select Date Range',
                    style: KCustomTextStyle.kBold(
                      context,
                      FontSize.kXLarge,
                      KConstantColors.blackColor,
                      KConstantFonts.haskoyBold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    startDate == null
                        ? 'Select start date'
                        : endDate == null
                        ? 'Select end date'
                        : '${startDate!.day} ${months[startDate!.month - 1]} - ${endDate!.day} ${months[endDate!.month - 1]}',
                    style: KCustomTextStyle.kRegular(
                      context,
                      FontSize.kMedium,
                      KConstantColors.greyColor,
                      KConstantFonts.haskoyMedium,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Calendar Section
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: KConstantColors.whiteColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Calendar Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          Text(
                            'Select Dates',
                            style: KCustomTextStyle.kBold(
                              context,
                              FontSize.kXLarge,
                              KConstantColors.blackColor,
                              KConstantFonts.haskoyBold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Select up to 4',
                            style: KCustomTextStyle.kRegular(
                              context,
                              FontSize.kMedium,
                              KConstantColors.greyColor,
                              KConstantFonts.haskoyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Month Navigation
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${months[currentMonth - 1]} $currentYear',
                            style: KCustomTextStyle.kBold(
                              context,
                              FontSize.kLarge,
                              KConstantColors.blackColor,
                              KConstantFonts.haskoyBold,
                            ),
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (currentMonth > 1) {
                                      currentMonth--;
                                    } else {
                                      currentMonth = 12;
                                      currentYear--;
                                    }
                                  });
                                },
                                child: const Icon(
                                  Icons.chevron_left,
                                  color: KConstantColors.blackColor,
                                ),
                              ),
                              const SizedBox(width: 20),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (currentMonth < 12) {
                                      currentMonth++;
                                    } else {
                                      currentMonth = 1;
                                      currentYear++;
                                    }
                                  });
                                },
                                child: const Icon(
                                  Icons.chevron_right,
                                  color: KConstantColors.blackColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Calendar Grid
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: GridView.count(
                          crossAxisCount: 7,
                          children: _buildCalendarGrid(context),
                        ),
                      ),
                    ),

                    // Done Button
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(20),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context, [startDate, endDate]);
                        },
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: KConstantColors.blackColor,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Center(
                            child: Text(
                              'Done',
                              style: KCustomTextStyle.kMedium(
                                context,
                                FontSize.kLarge,
                                KConstantColors.whiteColor,
                                KConstantFonts.haskoyMedium,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
