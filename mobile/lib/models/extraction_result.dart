/// Represents a single extracted URL link from video OCR, caption, or transcript.
class ExtractedLink {
  final String url;
  final String normalizedUrl;
  final String source; // "video_ocr" | "caption" | "transcript"
  final String? timestamp;
  final String? context;

  const ExtractedLink({
    required this.url,
    required this.normalizedUrl,
    required this.source,
    this.timestamp,
    this.context,
  });

  factory ExtractedLink.fromJson(Map<String, dynamic> json) {
    return ExtractedLink(
      url: json['url'] as String? ?? '',
      normalizedUrl: json['normalized_url'] as String? ?? '',
      source: json['source'] as String? ?? 'caption',
      timestamp: json['timestamp'] as String?,
      context: json['context'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'url': url,
    'normalized_url': normalizedUrl,
    'source': source,
    if (timestamp != null) 'timestamp': timestamp,
    if (context != null) 'context': context,
  };
}

/// Represents the full extraction result for an Instagram Reel or Video.
class ExtractionResult {
  final String reelUrl;
  final String shortcode;
  final String author;
  final String title;
  final double durationSeconds;
  final String caption;
  final String transcript;
  final List<Map<String, dynamic>> ocrSnippets;
  final String summaryTldr;
  final List<String> keyPoints;
  final List<ExtractedLink> videoLinks;
  final List<ExtractedLink> captionLinks;
  final String? thumbnailUrl;

  const ExtractionResult({
    required this.reelUrl,
    required this.shortcode,
    required this.author,
    required this.title,
    required this.durationSeconds,
    required this.caption,
    required this.transcript,
    required this.ocrSnippets,
    required this.summaryTldr,
    required this.keyPoints,
    required this.videoLinks,
    required this.captionLinks,
    this.thumbnailUrl,
  });

  factory ExtractionResult.fromJson(Map<String, dynamic> json) {
    return ExtractionResult(
      reelUrl: json['reel_url'] as String? ?? '',
      shortcode: json['shortcode'] as String? ?? '',
      author: json['author'] as String? ?? '',
      title: json['title'] as String? ?? '',
      durationSeconds: (json['duration_seconds'] as num?)?.toDouble() ?? 0.0,
      caption: json['caption'] as String? ?? '',
      transcript: json['transcript'] as String? ?? '',
      ocrSnippets: (json['ocr_snippets'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      summaryTldr: json['summary_tldr'] as String? ?? '',
      keyPoints: (json['key_points'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      videoLinks: (json['video_links'] as List<dynamic>?)
              ?.map((e) => ExtractedLink.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      captionLinks: (json['caption_links'] as List<dynamic>?)
              ?.map((e) => ExtractedLink.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      thumbnailUrl: json['thumbnail_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'reel_url': reelUrl,
    'shortcode': shortcode,
    'author': author,
    'title': title,
    'duration_seconds': durationSeconds,
    'caption': caption,
    'transcript': transcript,
    'ocr_snippets': ocrSnippets,
    'summary_tldr': summaryTldr,
    'key_points': keyPoints,
    'video_links': videoLinks.map((l) => l.toJson()).toList(),
    'caption_links': captionLinks.map((l) => l.toJson()).toList(),
    if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
  };
}

/// Represents a single post inside a profile result.
class PostItem {
  final String shortcode;
  final String url;
  final String author;
  final String title;
  final String caption;
  final bool isVideo;
  final double durationSeconds;
  final String thumbnail;
  final List<ExtractedLink> captionLinks;

  const PostItem({
    required this.shortcode,
    required this.url,
    required this.author,
    required this.title,
    required this.caption,
    required this.isVideo,
    required this.durationSeconds,
    required this.thumbnail,
    required this.captionLinks,
  });

  factory PostItem.fromJson(Map<String, dynamic> json) {
    return PostItem(
      shortcode: json['shortcode'] as String? ?? '',
      url: json['url'] as String? ?? '',
      author: json['author'] as String? ?? '',
      title: json['title'] as String? ?? '',
      caption: json['caption'] as String? ?? '',
      isVideo: json['is_video'] as bool? ?? false,
      durationSeconds: (json['duration_seconds'] as num?)?.toDouble() ?? 0.0,
      thumbnail: json['thumbnail'] as String? ?? '',
      captionLinks: (json['caption_links'] as List<dynamic>?)
              ?.map((e) => ExtractedLink.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'shortcode': shortcode,
    'url': url,
    'author': author,
    'title': title,
    'caption': caption,
    'is_video': isVideo,
    'duration_seconds': durationSeconds,
    'thumbnail': thumbnail,
    'caption_links': captionLinks.map((l) => l.toJson()).toList(),
  };
}

/// Represents the extraction result for a single photo or carousel post.
class PostExtractionResult {
  final String postUrl;
  final String shortcode;
  final String author;
  final String title;
  final String caption;
  final String thumbnail;
  final bool isVideo;
  final double durationSeconds;
  final String summaryTldr;
  final List<String> keyPoints;
  final List<ExtractedLink> captionLinks;
  final int imageCount;
  final List<Map<String, dynamic>> ocrFrames;

  const PostExtractionResult({
    required this.postUrl,
    required this.shortcode,
    required this.author,
    required this.title,
    required this.caption,
    required this.thumbnail,
    required this.isVideo,
    required this.durationSeconds,
    required this.summaryTldr,
    required this.keyPoints,
    required this.captionLinks,
    required this.imageCount,
    this.ocrFrames = const [],
  });

  factory PostExtractionResult.fromJson(Map<String, dynamic> json) {
    return PostExtractionResult(
      postUrl: json['post_url'] as String? ?? '',
      shortcode: json['shortcode'] as String? ?? '',
      author: json['author'] as String? ?? '',
      title: json['title'] as String? ?? '',
      caption: json['caption'] as String? ?? '',
      thumbnail: json['thumbnail'] as String? ?? '',
      isVideo: json['is_video'] as bool? ?? false,
      durationSeconds: (json['duration_seconds'] as num?)?.toDouble() ?? 0.0,
      summaryTldr: json['summary_tldr'] as String? ?? '',
      keyPoints: (json['key_points'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      captionLinks: (json['caption_links'] as List<dynamic>?)
              ?.map((e) => ExtractedLink.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      imageCount: json['image_count'] as int? ?? 1,
      ocrFrames: (json['ocr_frames'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'post_url': postUrl,
    'shortcode': shortcode,
    'author': author,
    'title': title,
    'caption': caption,
    'thumbnail': thumbnail,
    'is_video': isVideo,
    'duration_seconds': durationSeconds,
    'summary_tldr': summaryTldr,
    'key_points': keyPoints,
    'caption_links': captionLinks.map((l) => l.toJson()).toList(),
    'image_count': imageCount,
    'ocr_frames': ocrFrames,
  };
}

/// Represents the extraction result for a creator profile.
class ProfileExtractionResult {
  final String profileUrl;
  final String profileName;
  final String profileBio;
  final int postCount;
  final List<PostItem> posts;
  final String summaryTldr;
  final List<ExtractedLink> allCaptionLinks;

  const ProfileExtractionResult({
    required this.profileUrl,
    required this.profileName,
    required this.profileBio,
    required this.postCount,
    required this.posts,
    required this.summaryTldr,
    required this.allCaptionLinks,
  });

  factory ProfileExtractionResult.fromJson(Map<String, dynamic> json) {
    return ProfileExtractionResult(
      profileUrl: json['profile_url'] as String? ?? '',
      profileName: json['profile_name'] as String? ?? '',
      profileBio: json['profile_bio'] as String? ?? '',
      postCount: json['post_count'] as int? ?? 0,
      posts: (json['posts'] as List<dynamic>?)
              ?.map((e) => PostItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      summaryTldr: json['summary_tldr'] as String? ?? '',
      allCaptionLinks: (json['all_caption_links'] as List<dynamic>?)
              ?.map((e) => ExtractedLink.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'profile_url': profileUrl,
    'profile_name': profileName,
    'profile_bio': profileBio,
    'post_count': postCount,
    'posts': posts.map((p) => p.toJson()).toList(),
    'summary_tldr': summaryTldr,
    'all_caption_links': allCaptionLinks.map((l) => l.toJson()).toList(),
  };
}

