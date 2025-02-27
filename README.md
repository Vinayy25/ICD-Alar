# ICD-Alar

![ICD-11 Browser App Banner](https://via.placeholder.com/800x200/3498db/ffffff?text=ICD-11+Browser)  
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0.en.html)  
[![Flutter](https://img.shields.io/badge/Flutter-3.0.0+-blue.svg)](https://flutter.dev)  
[![Platform](https://img.shields.io/badge/Platform-Android%20|%20iOS-lightgrey.svg)](https://flutter.dev/docs/deployment)

**A modern, feature-rich mobile application** designed for healthcare professionals and medical coders to browse and navigate the [ICD-11 (International Classification of Diseases 11th Revision)](https://www.who.int/standards/classifications/classification-of-diseases) medical classification system. Built with [Flutter](https://flutter.dev) for a seamless cross-platform experience.

---

## 📋 Table of Contents

- [ICD-Alar](#icd-alar)
  - [📋 Table of Contents](#-table-of-contents)
  - [🌟 Overview](#-overview)
  - [✨ Features](#-features)
    - [Core Functionality](#core-functionality)
    - [User Experience Enhancements](#user-experience-enhancements)
    - [Technical Features](#technical-features)
  - [🔧 Technical Architecture](#-technical-architecture)
    - [Stack and Dependencies](#stack-and-dependencies)
    - [Data Flow](#data-flow)
  - [📱 Installation](#-installation)
    - [Requirements](#requirements)
    - [Build from Source](#build-from-source)
    - [Download](#download)
  - [📖 Usage](#-usage)
    - [Basic Navigation](#basic-navigation)
    - [Advanced Features](#advanced-features)
  - [🎨 Design Philosophy](#-design-philosophy)
    - [UI/UX Highlights](#uiux-highlights)
  - [🚀 Future Roadmap](#-future-roadmap)
  - [👥 Contributing](#-contributing)
  - [📄 License](#-license)
  - [📞 Contact](#-contact)

---

## 🌟 Overview

**ICD-Alar** is a powerful mobile tool crafted for healthcare professionals, medical coders, and researchers who require efficient access to the ICD-11 classification system. This app connects directly to the [World Health Organization's (WHO) ICD-11 API](https://icd.who.int/en), ensuring that all data is accurate and up-to-date. With a sleek, intuitive interface built using Flutter, ICD-Alar delivers a responsive experience on both Android and iOS devices.

Whether you're in a busy clinical environment or conducting in-depth medical research, ICD-Alar simplifies the process of exploring and utilizing the ICD-11 codes.

---

## ✨ Features

### Core Functionality

- **Complete ICD-11 Navigation**: Explore all chapters, blocks, categories, and codes within the ICD-11 system.
- **Code Searching**: Rapidly locate specific codes with an efficient search tool.
- **Detailed Code Information**: Access in-depth details for each code, including:
  - Full definitions
  - Exclusions
  - Inclusion terms
  - "Coded elsewhere" references
  - Related categories (e.g., perinatal chapter)

### User Experience Enhancements

- **Intuitive Navigation**: Seamless transitions between chapters and categories.
- **Copy Functionality**: One-tap code copying for use in medical documentation.
- **Offline Support**: Review recently accessed codes without an internet connection via caching.
- **Modern Design**: Clean, accessible UI optimized for readability and usability.
- **Markdown Support**: Medical definitions formatted clearly using Markdown.
- **Animated Interface**: Subtle animations that enhance the experience without overwhelming the user.

### Technical Features

- **Real-time API Integration**: Direct connection to the WHO's ICD-11 API for live data.
- **Efficient Data Caching**: Reduces data usage and boosts performance.
- **Responsive Layout**: Adapts to various screen sizes and orientations.
- **Loading States**: Skeleton screens provide feedback during data loading.
- **Error Handling**: User-friendly error messages for a smooth experience.

---

## 🔧 Technical Architecture

### Stack and Dependencies

- **Framework**: [Flutter](https://flutter.dev)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **API Integration**: Custom HTTP service with RESTful API support
- **UI Components**:
  - [`flutter_advanced_drawer`](https://pub.dev/packages/flutter_advanced_drawer)
  - [`flutter_animate`](https://pub.dev/packages/flutter_animate)
  - [`animations`](https://pub.dev/packages/animations)
  - [`flutter_markdown`](https://pub.dev/packages/flutter_markdown)
  - [`skeletonizer`](https://pub.dev/packages/skeletonizer)
- **Local Storage**: [`shared_preferences`](https://pub.dev/packages/shared_preferences) for caching

### Data Flow

1. **API Layer**: Fetches data from WHO's ICD-11 API endpoints.
2. **Caching Layer**: Stores data locally using `shared_preferences` for offline access.
3. **State Management**: Utilizes the Provider pattern for efficient app-wide state handling.
4. **UI Layer**: Renders data with smooth transitions and responsive layouts.

![Data Flow Diagram](https://via.placeholder.com/600x300/cccccc/000000?text=ICD-Alar+Data+Flow)  
_Replace this placeholder with an actual diagram for a professional touch._

---

## 📱 Installation

### Requirements

- **Flutter**: 3.0.0 or higher
- **Dart**: 2.17.0 or higher
- **Supported OS**: Android 5.0+ or iOS 11.0+

### Build from Source

1. **Clone the repository**:

   ```bash
   git clone https://github.com/yourusername/icd-alar.git
   ```

2. **Navigate to the project directory**:

   ```bash
   cd icd-alar
   ```

3. **Install dependencies**:

   ```bash
   flutter pub get
   ```

4. **Run the app**:

   ```bash
   flutter run
   ```

### Download

_Coming soon to the [Google Play Store](https://play.google.com) and [Apple App Store](https://www.apple.com/app-store/)._

---

## 📖 Usage

### Basic Navigation

- **Browse Chapters**: Launch the app to view all ICD-11 chapters.
- **Explore Categories**: Tap a chapter to dive into its sections and categories.
- **View Details**: Select a category to see comprehensive code details.
- **Copy Codes**: Tap the copy button to add codes to your clipboard instantly.

### Advanced Features

- **Search**: Find specific codes or terms using the search bar.
- **Drawer Menu**: Access additional tools via the advanced drawer.
- **Favorites**: _(Coming soon)_ Save codes for quick reference.
- **History**: _(Coming soon)_ Review your recently viewed codes.

![Usage Screenshot](https://via.placeholder.com/300x600/cccccc/000000?text=ICD-Alar+Screenshot)  
_Add real screenshots or GIFs here to showcase the app in action._

---

## 🎨 Design Philosophy

ICD-Alar is built on principles tailored to the needs of healthcare professionals:

- **Clarity**: Accurate, easy-to-read medical information.
- **Efficiency**: Fast access to codes with minimal effort.
- **Reliability**: Consistent performance, even offline or with unstable connections.
- **Modern**: A professional, up-to-date interface.
- **Accessibility**: Designed for all users, including those with visual impairments.

### UI/UX Highlights

- **Color-coded Sections**: Visually distinguish chapters, blocks, and categories.
- **Thoughtful Animations**: Enhance usability without distraction.
- **Readable Typography**: Optimized for medical terminology.
- **Consistent Navigation**: Intuitive patterns for effortless use.

---

## 🚀 Future Roadmap

We’re excited to keep improving ICD-Alar. Here’s what’s on the horizon:

- **Offline Mode**: Full functionality with downloadable databases.
- **Search Enhancements**: Filters and fuzzy matching for advanced searches.
- **Favorites System**: Save and manage frequently used codes.
- **History Tracking**: Quick access to recently viewed codes.
- **Notes & Annotations**: Add custom notes to codes.
- **Cross-References**: Visualize relationships between codes.
- **Dark Mode**: Support for low-light environments.
- **Tablet Optimization**: Enhanced layouts for larger screens.

---

## 👥 Contributing

We welcome contributions to ICD-Alar! Whether you have feature ideas, bug reports, or code to share, your input is valued.

1. **Fork the repository**.
2. **Create a feature branch**:

   ```bash
   git checkout -b feature/amazing-feature
   ```

3. **Commit your changes**:

   ```bash
   git commit -m 'Add some amazing feature'
   ```

4. **Push to the branch**:

   ```bash
   git push origin feature/amazing-feature
   ```

5. **Open a Pull Request**.

Please follow the project’s style guidelines and include tests where applicable.

---

## 📄 License

This project is licensed under the [GNU General Public License v3.0](https://www.gnu.org/licenses/gpl-3.0.en.html). See the [LICENSE](link/to/license) file for details. The GPL v3 ensures that ICD-Alar remains open source, with all derivatives also freely available.

---

## 📞 Contact

**Developer**: Vinayachandra  
**Email**: [vinaychandra166@gmail.com](mailto:vinaychandra166@gmail.com)  
**Phone**: +91 7996336041

Feel free to reach out with questions, feedback, or collaboration ideas!

---

_Disclaimer: This application is not officially affiliated with the World Health Organization (WHO) or the ICD-11 project. It is an independent tool designed to facilitate access to publicly available ICD-11 data via the WHO’s API._

---
