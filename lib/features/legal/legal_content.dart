// lib/features/legal/legal_content.dart
//
// Single source of truth for the in-app legal pages. The same text lives in
// docs/*.html for GitHub Pages (the public URLs Play Console asks for).
// If you change one, change the other.

/// ⚠️ Replace before publishing (also in docs/*.html).
const String kSupportEmail = 'aliraza.bdn01@gmail.com';

/// ⚠️ Replace with your GitHub Pages base URL after publishing, e.g.
/// https://<username>.github.io/<repo>
const String kLegalBaseUrl = 'https://YOUR_USERNAME.github.io/YOUR_REPO';

const String kLastUpdated = '18 November 2026';

class LegalSection {
  final String heading;
  final List<String> paragraphs;
  final List<String> bullets;
  const LegalSection(this.heading, {this.paragraphs = const [], this.bullets = const []});
}

class LegalDocument {
  final String title;
  final String intro;
  final List<LegalSection> sections;
  const LegalDocument(this.title, this.intro, this.sections);
}

const LegalDocument privacyPolicy = LegalDocument(
  'Privacy Policy',
  'ProNear ("we", "us") connects customers with nearby service providers '
      '(electricians, plumbers, AC technicians, carpenters and more) and local '
      'businesses. This policy explains what we collect, why, and the choices you have. '
      'Last updated: $kLastUpdated.',
  [
    LegalSection(
      '1. Information we collect',
      paragraphs: ['All users:'],
      bullets: [
        'Email address (used to sign in and to verify your account with a one-time code).',
        'Name and phone number.',
        'Profile photo (optional).',
        'Approximate and precise location, only while you use the app, to show nearby providers and set your service area.',
        'Service requests, orders, reviews, favourites and the chat messages and images you send.',
        'Basic technical data (such as app crashes) needed to keep the app working.',
      ],
    ),
    LegalSection(
      '',
      paragraphs: ['Service providers and businesses additionally:'],
      bullets: [
        'CNIC number and photos of the front and back of your CNIC.',
        'A selfie (face photo) taken during registration.',
        'CV / profile details, certificates, portfolio photos and videos, business details and product photos.',
      ],
    ),
    LegalSection(
      '2. Why we use it',
      bullets: [
        'To create and secure your account and verify your email.',
        'To show nearby providers and let customers send requests and orders.',
        'To let a provider and a customer chat after a request is accepted.',
        'To verify the identity of providers so customers can trust them. Verification photos are reviewed manually by our team and are never shown to other users.',
        'To send notifications about requests, messages and status changes.',
        'To prevent fraud and abuse and to comply with the law.',
      ],
    ),
    LegalSection(
      '3. Who can see your information',
      bullets: [
        'Other users see only what is needed to use the service: your name, profile photo, online status and, for providers, profile, services, portfolio, ratings and approximate distance.',
        'Your CNIC number, CNIC photos and face photo are stored privately. Only you and our verification team can access them.',
        'Chat messages are visible only to the two people in the conversation.',
        'We do not sell your personal data and we do not use it for advertising.',
      ],
    ),
    LegalSection(
      '4. Where it is stored and how it is protected',
      paragraphs: [
        'Data is stored with our cloud provider Supabase (database, file storage and authentication). '
            'Data is encrypted in transit (HTTPS) and at rest. Verification images are kept in a private storage area with access limited to the owner of the account and authorised staff. '
            'No system is 100% secure, but we work to protect your data.',
      ],
    ),
    LegalSection(
      '5. Device permissions',
      bullets: [
        'Camera: to photograph your CNIC and face during provider registration and to add portfolio photos.',
        'Photos / gallery: to choose a profile, portfolio, product or chat image.',
        'Location: to find providers near you and to set a provider\'s service location.',
        'Microphone / speech recognition: only for voice search, when you tap the microphone button.',
        'Notifications: to alert you about new requests and messages.',
        'You can change these permissions at any time in your phone settings.',
      ],
    ),
    LegalSection(
      '6. How long we keep data',
      paragraphs: [
        'We keep your data while your account is active. When you delete your account, your profile, '
            'messages, requests, portfolio, photos and verification images are deleted (see Account Deletion). '
            'We may keep limited records where the law requires it.',
      ],
    ),
    LegalSection(
      '7. Your choices and rights',
      bullets: [
        'Access and update your profile information in the app.',
        'Delete your account and data at any time from Profile → Delete Account, or by emailing us.',
        'Withdraw permissions in your phone settings.',
      ],
    ),
    LegalSection(
      '8. Children',
      paragraphs: ['ProNear is intended for people aged 18 and over. We do not knowingly collect data from children.'],
    ),
    LegalSection(
      '9. Changes to this policy',
      paragraphs: ['We may update this policy. The "last updated" date above shows the latest version. Continued use of the app means you accept the updated policy.'],
    ),
    LegalSection(
      '10. Contact',
      paragraphs: ['Questions or requests: $kSupportEmail'],
    ),
  ],
);

const LegalDocument termsOfService = LegalDocument(
  'Terms of Service',
  'By creating an account or using ProNear you agree to these terms. Last updated: $kLastUpdated.',
  [
    LegalSection(
      '1. What ProNear is',
      paragraphs: [
        'ProNear is a platform that helps customers find and contact independent service providers and local businesses. '
            'We are not the employer, agent or contractor of any provider, and we do not perform the services ourselves.',
      ],
    ),
    LegalSection(
      '2. Accounts',
      bullets: [
        'You must be 18 or older and provide accurate information.',
        'Keep your password confidential. You are responsible for activity on your account.',
        'One person, one account. Providers must use their own genuine CNIC and face photo.',
      ],
    ),
    LegalSection(
      '3. Providers',
      bullets: [
        'Providers must complete identity verification. A verification badge means our team reviewed the documents; it is not a guarantee of quality or a licence.',
        'Providers are responsible for the quality, safety, price and legality of their work and for any permits or taxes required.',
        'Fake documents, impersonation or another person\'s photos will lead to account removal and may be reported to the authorities.',
      ],
    ),
    LegalSection(
      '4. Customers',
      bullets: [
        'Agree the scope and price directly with the provider. Payment is made directly between you and the provider; ProNear does not handle payments.',
        'Be respectful. Do not send false requests or abuse providers.',
        'Reviews must be honest and based on a real completed job.',
      ],
    ),
    LegalSection(
      '5. Acceptable use',
      paragraphs: ['You must not:'],
      bullets: [
        'Post unlawful, offensive, misleading or infringing content.',
        'Harass, threaten or scam other users.',
        'Attempt to access other users\' data, disrupt the service, or reverse-engineer the app.',
        'Use the platform for anything other than genuine service or product requests.',
      ],
    ),
    LegalSection(
      '6. Content you upload',
      paragraphs: [
        'You keep ownership of your photos, videos and text. You allow us to store and display them within the app so the service can work. '
            'You confirm you have the right to upload them.',
      ],
    ),
    LegalSection(
      '7. Suspension and termination',
      paragraphs: [
        'We may suspend or remove accounts that break these terms or put others at risk. '
            'You can delete your account at any time (Profile → Delete Account).',
      ],
    ),
    LegalSection(
      '8. Disclaimer and liability',
      paragraphs: [
        'The app is provided "as is". We do not guarantee that any provider will respond, be available, or deliver a particular result, '
            'and we are not responsible for disputes, damage, injury or loss arising from services arranged through the app, '
            'to the extent permitted by law. Take sensible precautions when meeting someone or letting them into your home.',
      ],
    ),
    LegalSection(
      '9. Changes',
      paragraphs: ['We may update these terms. Continued use after an update means you accept the new terms.'],
    ),
    LegalSection(
      '10. Contact',
      paragraphs: ['$kSupportEmail'],
    ),
  ],
);

const LegalDocument accountDeletion = LegalDocument(
  'Delete Your Account',
  'You can delete your ProNear account and the data linked to it at any time. Last updated: $kLastUpdated.',
  [
    LegalSection(
      'Option 1: inside the app (instant)',
      bullets: [
        'Open ProNear and log in.',
        'Go to Profile.',
        'Tap "Delete Account" and confirm.',
        'Your account is deleted immediately and you are logged out.',
      ],
    ),
    LegalSection(
      'Option 2: by email',
      paragraphs: [
        'If you can no longer open the app, email $kSupportEmail from the email address registered on your account '
            'with the subject "Delete my ProNear account". We will verify the request and delete the account within 30 days.',
      ],
    ),
    LegalSection(
      'What is deleted',
      bullets: [
        'Your login (email and password) and profile details.',
        'Profile photo, portfolio photos and videos, business and product photos.',
        'For providers: CNIC number, CNIC photos, face photo and CV / certificates.',
        'Your service requests, orders, favourites, reviews you wrote, notifications and chat messages.',
      ],
    ),
    LegalSection(
      'What may be kept',
      paragraphs: [
        'Limited records required by law or to prevent fraud (for example, a record that an account was removed for abuse) may be kept for a limited time.',
      ],
    ),
    LegalSection(
      'This cannot be undone',
      paragraphs: ['Deleted accounts and data cannot be restored. You can create a new account at any time.'],
    ),
  ],
);
