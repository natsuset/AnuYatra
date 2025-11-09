# Anuyātrā - Product Requirements Document (Current State)

## Executive Summary

**Anuyātrā** is a premium matrimony application that combines traditional matchmaking with modern technology. The app features a dual-module architecture consisting of the core **Matrimony Hub** for essential matchmaking services and **Vivaha Samskara** for premium wedding preparation services, enhanced with revolutionary features for trust verification, financial transparency, and virtual family interactions.

---

## App Architecture

```
Anuyātrā App
├── Matrimony Hub (Core Service)
│   ├── Profile Discovery & Matching
│   ├── Family & Broker Communication
│   └── Interest Management
│
├── Vivaha Samskara (Premium Module)
│   ├── Beauty Transformation
│   ├── Health & Wellness
│   ├── Cultural Learning
│   ├── Financial Planning
│   └── Spiritual Guidance
│
└── Revolutionary Features
    ├── Trust & Verification Center
    ├── Financial Compatibility Center
    └── Virtual Family Meets Center
```

---

## Design Philosophy

### Visual Identity
- **Primary Colors**: Sacred Saffron (#FF6B35), Deep Maroon (#8B0000)
- **Secondary Colors**: Soft Off-White (#FAFAFA), WhatsApp Green (#25D366)
- **Design Language**: WhatsApp-inspired familiar interface with premium Indian cultural elements
- **Typography**: System fonts (Inter-style) for reliability and consistency

### UX Principles
- **Familiar Navigation**: Bottom tab navigation similar to WhatsApp
- **Chat-Style Interface**: Profile interactions mimic messaging apps
- **Premium Feel**: Card-based layouts with shadows and gradients
- **Responsive Design**: Optimized for all screen sizes with flexible layouts

---

## Core Features

### 1. Matrimony Hub (Core Service)

#### 1.1 Home Screen
**Purpose**: Primary profile discovery interface
**UI Description**:
- **Layout**: WhatsApp-style conversation list
- **Profile Cards**: 
  - Rectangular photos (80x100px) with rounded corners
  - Colorful placeholder avatars with initials when no photo
  - Name, profession, education, city information
  - Height with icon indicator
  - Status badges (Premium, Verified, etc.)
  - Last seen/activity timestamp
- **Pinned Broker**: Always visible at the top for easy access
- **Background**: Clean white with subtle shadows on cards

#### 1.2 Profile Detail Screen
**Purpose**: Detailed profile viewing with interaction options
**UI Description**:
- **Layout**: Chat-style interface with profile information as messages
- **Chat Bubbles**: Different colors for different information types
- **Action Bar**: Bottom fixed bar with "Interested", "Not a Match", "Save" buttons
- **Navigation**: Back button with profile name in header

#### 1.3 Shortlist Screen
**Purpose**: Saved profiles management
**UI Description**:
- **Grid Layout**: Responsive grid showing saved profiles
- **Profile Cards**: Compact cards with photos and basic info
- **Empty State**: "Browse Profiles" button to navigate to home
- **Background**: Consistent with app theme

#### 1.4 Broker Contact Screen
**Purpose**: Direct communication with matrimony broker
**UI Description**:
- **Chat Interface**: WhatsApp-style messaging
- **Message Bubbles**: Different colors for sent/received messages
- **Input Field**: Bottom text input with send button
- **Header**: Broker name and online status

### 2. Vivaha Samskara (Premium Module)

#### 2.1 Premium Dashboard
**Purpose**: Central hub for all premium services
**UI Description**:
- **Header**: SliverAppBar with gradient background (Sacred Saffron to Deep Maroon)
- **Progress Overview**: Circular progress indicator with percentage completion
- **Today's Tasks**: Horizontal scrollable cards (220px width)
- **Upcoming Appointments**: List of appointment cards with time and action buttons
- **Premium Services**: Responsive grid (2 columns on mobile, adjusts for larger screens)
- **Animations**: Fade and slide transitions for enhanced premium feel

#### 2.2 Premium Service Cards
**UI Description**:
- **Dimensions**: Aspect ratio 0.75 for optimal content fit
- **Content**: Service icon, title (13px), description (10px), progress bar (3px height)
- **Styling**: White cards with shadows and rounded corners
- **Responsive**: Flexible layout preventing overflow on all screen sizes

#### 2.3 Individual Service Screens

##### Beauty Transformation Screen
- **Service Features**: Skincare consultation, makeup tutorials, styling sessions
- **Progress Tracking**: Visual progress cards with completion percentages
- **Appointments**: Scheduled beauty consultations with specialists

##### Health & Wellness Screen  
- **Service Features**: Fitness planning, nutrition guidance, mental wellness
- **Progress Tracking**: Health metrics and goal achievements
- **Appointments**: Doctor consultations and fitness sessions

##### Cultural Learning Screen
- **Service Features**: Traditional customs, language learning, cultural etiquette
- **Progress Tracking**: Learning modules completion
- **Appointments**: Cultural mentor sessions

### 3. Revolutionary Features

#### 3.1 Trust & Verification Center
**Purpose**: Community-driven profile verification system
**UI Description**:
- **Verification Status Cards**: Visual indicators for different verification levels
- **Community Endorsements**: List of endorsements from verified community members
- **Trust Score**: Numerical trust score with breakdown
- **Verification Process**: Step-by-step guide for profile verification
- **Background Checks**: Integration with verification services

**Key Features**:
- Identity verification through government documents
- Community endorsement system
- Professional verification for career claims
- Family verification through mutual connections
- Trust score algorithm based on multiple factors

#### 3.2 Financial Compatibility Center
**Purpose**: Transparent financial planning and compatibility assessment
**UI Description**:
- **Financial Profile Cards**: Income, savings, investments overview
- **Compatibility Scores**: Visual compatibility metrics
- **Budget Planning Tools**: Wedding budget breakdown and planning
- **Investment Goals**: Shared financial goal tracking
- **Transparency Settings**: Privacy controls for financial information

**Key Features**:
- Financial profile creation and verification
- Compatibility scoring based on financial goals
- Wedding budget planning tools
- Investment and savings goal alignment
- Financial counselor consultations

#### 3.3 Virtual Family Meets Center
**Purpose**: AI-powered virtual family interaction platform
**UI Description**:
- **Meeting Rooms**: Virtual spaces for family video calls
- **AI Suggestions**: Smart conversation starters and cultural guidance
- **Scheduling System**: Calendar integration for meeting planning
- **Recording Features**: Optional meeting recordings with consent
- **Cultural Guidelines**: Built-in etiquette and cultural sensitivity tips

**Key Features**:
- HD video calling with multiple participants
- AI-powered conversation suggestions
- Cultural context awareness
- Meeting scheduling and reminders
- Privacy controls and consent management

---

## Navigation Structure

### Bottom Navigation (5 Tabs)
1. **Home** - Profile discovery (Primary tab)
2. **Shortlist** - Saved profiles
3. **Broker** - Direct broker communication
4. **Premium** - Vivaha Samskara dashboard
5. **Features** - Revolutionary features access

### Navigation Flow
- **Tab-based navigation** using IndexedStack for state preservation
- **Premium styling** with enhanced animations and visual feedback
- **Responsive indicators** adapting to different screen sizes

---

## Technical Implementation

### Architecture
- **Framework**: Flutter with Material Design
- **State Management**: StatefulWidget with AnimationController
- **Navigation**: Bottom navigation with IndexedStack
- **Image Loading**: CachedNetworkImage with placeholder fallbacks
- **Responsive Design**: MediaQuery-based responsive breakpoints

### Key Components
- **Custom Themes**: AppTheme with consistent color palette
- **Reusable Widgets**: ProfileListItem, ChatBubble, ServiceCard components
- **Data Models**: Profile, Broker, PremiumService, TrustVerification models
- **Mock Data**: Comprehensive mock data for development and testing

### Performance Optimizations
- **Lazy Loading**: Efficient list rendering with proper scrolling
- **Image Caching**: Network image caching for better performance
- **State Preservation**: Navigation state maintained across tab switches
- **Responsive Layouts**: Flexible layouts preventing overflow on all devices

---

## Data Models

### Core Models
- **Profile**: Personal information, photos, preferences, verification status
- **Broker**: Contact information, availability, chat history
- **PremiumService**: Service details, progress tracking, appointment scheduling

### Revolutionary Features Models
- **TrustVerification**: Verification levels, endorsements, trust scores
- **FinancialProfile**: Income details, savings, investment preferences
- **VirtualMeeting**: Meeting details, AI suggestions, participant management

---

## Current Status

### Completed Features ✅
- Complete Matrimony Hub with all core screens
- Full Vivaha Samskara premium module
- All three Revolutionary Features centers
- Responsive design across all components
- Professional UI with premium feel
- Consistent theming and branding
- Mock data integration

### Platform Support ✅
- **iOS**: Bundle ID configured as `com.sowrya.AnuYatraMatrimony`
- **Android**: Ready for deployment
- **App Display Name**: "Anuyātrā" across all platforms

---

## Design Specifications

### Color Palette
```
Primary Colors:
- Sacred Saffron: #FF6B35
- Deep Maroon: #8B0000

Secondary Colors:
- Soft Off-White: #FAFAFA
- WhatsApp Green: #25D366
- Premium Gold: #FFD700
- Trust Blue: #1976D2
```

### Typography
- **Headers**: 18-24px, Bold
- **Body Text**: 14-16px, Regular
- **Captions**: 10-12px, Medium
- **Button Text**: 14px, Medium

### Spacing & Layout
- **Card Padding**: 12-16px
- **Section Margins**: 16-24px  
- **Border Radius**: 8-12px for cards
- **Shadow Elevation**: 2-4px for depth

---

## Success Metrics

### User Engagement
- Profile view time and interaction rates
- Broker conversation frequency
- Premium service utilization
- Revolutionary features adoption

### Trust & Safety
- Profile verification completion rates
- Community endorsement participation
- Trust score improvements
- Successful family meetings

### Revenue Metrics
- Premium module subscription rates
- Service completion rates
- User retention and lifetime value
- Feature-specific conversion rates

---

## Conclusion

Anuyātrā successfully combines traditional matrimony services with modern technology and innovative features. The app provides a familiar, WhatsApp-inspired interface while offering premium services and revolutionary features that enhance the marriage search experience. The responsive design and professional UI ensure accessibility across all devices while maintaining a premium feel that justifies the value proposition.

The current implementation provides a solid foundation for launch with comprehensive features spanning core matrimony services, premium wedding preparation, and innovative trust and compatibility assessment tools.
