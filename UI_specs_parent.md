Anuyātrā - The real matrimony app

This app UI will have multiple profiles with screens designed differently for each profile.

The profiles for now will be of 3 types:
1. Parent
2. Broker
3. Candidate

📱 UI Specification Document: Anuyātrā – Parent App

Design Philosophy:

Look and feel should mimic WhatsApp → familiar, minimal learning curve.

Prioritize clarity, trust, and simplicity.

Large photos, clean text, and limited actions (✅ Interested, ❌ Not a Match, ⭐ Save).

Always keep broker access visible for reassurance.

1. Home Screen (Profile List – WhatsApp Chat Style)

Layout: Vertical list, identical to WhatsApp’s chat list.

Each row (profile item):

Left: Circular profile photo (large, clear).

Middle (2 text lines):

Line 1: Name, Age – Profession (bold, e.g. “Rohit Sharma, 28 – Software Engineer”)

Line 2: Snippet: Education + City (e.g. “M.Tech, Bangalore”)

Right: Small badge for new profiles (green dot 🔵).

Top row: Always pinned → “Your Broker” contact.

Header: Agency logo + title “Anuyātrā” at top.

2. Profile Detail Screen (Chat-Like)

Layout: Should mimic a WhatsApp chat thread.

Left-side messages (sent by broker):

Large photo(s) of candidate.

Text message block with:

Name, Age, Height

Profession & Education

Family background (father/mother occupations, siblings if relevant)

City & Community (optional)

Right-side messages (parent actions):

✅ Interested → green bubble

❌ Not a Match → red bubble

⭐ Save for Later → yellow bubble

Footer: Fixed bar with 3 large buttons:

[✅ Interested] [❌ Not a Match] [⭐ Save]

3. Shortlist Screen (Starred Messages / Pinned Chats)

Layout: Similar to WhatsApp “Starred Messages.”

Content: Grid or list of profiles parents liked.

Each shows profile photo + Name, Age, Profession.

Status label below (e.g. “Awaiting Response,” “Mutual Interest”).

Header: “Your Shortlist.”

4. Updates/Notifications

Style: Same as WhatsApp unread messages.

Examples:

“5 New Profiles shared by your broker.”

“Sharma Family has shown interest in your daughter’s profile.”

Indicator: Green dot 🔵 on Home list until opened.

5. Broker Contact (Pinned Chat)

Top pinned row: Always visible “Your Broker.”

Inside screen: Chat-like interface for direct communication.

Voice note option (important for less tech-savvy parents).

Call button always available.

6. Navigation

Bottom Navigation Bar (3 tabs only):

🏠 Home (Profile List)

⭐ Shortlist

📞 Broker

👉 Keeps app uncluttered, no hidden menus.

🎨 Design Guidelines

Color Palette:

Primary = Sacred Saffron (#FF8C42) for CTAs.

Secondary = Deep Maroon (#8B2635) for headers.

Background = Soft off-white (#FAFAFA).

Typography:

Use a clear, sans-serif font (like Inter, Noto Sans, or system default).

Bold for names & statuses, regular for descriptions.

Icons: Stick to WhatsApp-style minimal icons (tick, star, cross).

🧭 User Flow

Open App → Home Screen: List of new profiles (chat-style).

Tap Profile → Profile Detail: Shown as chat thread with info + actions.

Parent Action: Tap ✅ / ❌ / ⭐ → response sent, status updated.

View Shortlist: Check saved profiles with status.

Broker Contact: Call/message anytime via pinned chat.





Anuyātrā App
├── Matrimony Hub (Core Service)
│   ├── Profile Search & Matching
│   ├── Family & Broker Tools
│   └── Communication Features
│
└── Vivaha Samskara (Premium Module)
    ├── Beauty Transformation
    ├── Health & Wellness  
    ├── Cultural Learning
    ├── Financial Planning
    └── Spiritual Guidance
