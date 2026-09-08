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
    networkImageUrl:
        "https://images.unsplash.com/photo-1540518614846-7eded433c457?q=80&w=1000&auto=format&fit=crop",
  ),
  OnboardingItem(
    title: "Join the Community",
    description:
        "Sign up to view your room details, rent agreement, and start your stress-free campus living experience.",
    networkImageUrl: "",
    isSplitLayout: true,
    splitTopImage:
        "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?q=80&w=1000&auto=format&fit=crop",
    splitBottomImage:
        "https://images.unsplash.com/photo-1617806118233-18e1de247200?q=80&w=1000&auto=format&fit=crop",
  ),
];
