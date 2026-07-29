import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../home/presentation/widgets/section_header.dart';

class CharacterListWidget extends StatelessWidget {
  const CharacterListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Characters'),
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: 10,
            itemBuilder: (context, index) {
              final characters = [
                {'name': 'Xiao Yan', 'role': 'Main', 'image': 'https://via.placeholder.com/80x80'},
                {'name': 'Yun Yun', 'role': 'Supporting', 'image': 'https://via.placeholder.com/80x80'},
                {'name': 'Xun Er', 'role': 'Main', 'image': 'https://via.placeholder.com/80x80'},
                {'name': 'Medusa', 'role': 'Supporting', 'image': 'https://via.placeholder.com/80x80'},
                {'name': 'Nalan Yanran', 'role': 'Supporting', 'image': 'https://via.placeholder.com/80x80'},
                {'name': 'Yao Lao', 'role': 'Main', 'image': 'https://via.placeholder.com/80x80'},
                {'name': 'Gu He', 'role': 'Supporting', 'image': 'https://via.placeholder.com/80x80'},
                {'name': 'Hai Bodong', 'role': 'Supporting', 'image': 'https://via.placeholder.com/80x80'},
                {'name': 'Fa Ma', 'role': 'Supporting', 'image': 'https://via.placeholder.com/80x80'},
                {'name': 'Xiao Li', 'role': 'Supporting', 'image': 'https://via.placeholder.com/80x80'},
              ];
              
              final char = characters[index];
              
              return Container(
                width: 90,
                margin: EdgeInsets.only(right: 14),
                child: Column(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: (char['role'] == 'Main')
                              ? AppTheme.primaryColor
                              : AppTheme.textHint.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: char['image']!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: AppTheme.cardColor,
                            highlightColor: AppTheme.surfaceColor,
                            child: Container(color: AppTheme.cardColor),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppTheme.cardColor,
                            child: Icon(Icons.person, color: AppTheme.textHint),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      char['name']!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2),
                    Text(
                      char['role']!,
                      style: TextStyle(
                        fontSize: 10,
                        color: char['role'] == 'Main'
                            ? AppTheme.primaryColor
                            : AppTheme.textHint,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    ).animate().fadeIn(duration: Duration(milliseconds: 400));
  }
}
