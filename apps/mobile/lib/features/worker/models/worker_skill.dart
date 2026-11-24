class SkillCategory {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final List<WorkerSkillItem> skills;

  const SkillCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.skills = const [],
  });

  factory SkillCategory.fromJson(
    Map<String, dynamic> json, {
    List<WorkerSkillItem> skills = const [],
  }) {
    return SkillCategory(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String?,
      skills: skills,
    );
  }
}

class WorkerSkillItem {
  final String id;
  final String categoryId;
  final String name;
  final String? categoryName;
  final String? customSkillName;

  const WorkerSkillItem({
    required this.id,
    required this.categoryId,
    required this.name,
    this.categoryName,
    this.customSkillName,
  });

  factory WorkerSkillItem.fromJson(Map<String, dynamic> json) {
    return WorkerSkillItem(
      id: json['id'] as String? ?? json['skill_id'] as String? ?? '',
      categoryId: json['category_id'] as String? ?? '',
      name: json['name'] as String? ?? json['skill_name'] as String? ?? '',
      categoryName: json['category_name'] as String?,
      customSkillName: json['custom_skill_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'name': name,
      if (categoryName != null) 'category_name': categoryName,
      if (customSkillName != null) 'custom_skill_name': customSkillName,
    };
  }
}
