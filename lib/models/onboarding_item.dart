class OnboardingItem {
  final String title;
  final String description;
  final String? imagePath;
  final String networkImageUrl;
  final bool isSplitLayout;
  final String? splitTopImage;
  final String? splitBottomImage;

  OnboardingItem({
    required this.title,
    required this.description,
    this.imagePath,
    this.networkImageUrl = "",
    this.isSplitLayout = false,
    this.splitTopImage,
    this.splitBottomImage,
  });
}

final List<OnboardingItem> onboardingItems = [
  OnboardingItem(
    title: "Welcome to Lakshya Residency",
    description: "Discover premium student housing designed for your success.",
    imagePath: "assets/buildings/Tirupati.png",
  ),
  OnboardingItem(
    title: "All-Inclusive Amenities",
    description:
        "Mess, laundry, pick & drop, and electricity—everything you need in one package.",
    imagePath: "assets/images/onboarding_living_room.jpg",
  ),
  OnboardingItem(
    title: "Join the Community",
    description:
        "Sign up to view your room details, rent agreement, and start your stress-free campus living experience.",
    imagePath: "assets/images/onboarding_bedroom.jpg",
    isSplitLayout: true,
    splitTopImage: "assets/images/onboarding_bedroom.jpg",
    splitBottomImage: "assets/images/onboarding_balcony.jpg",
  ),
];
