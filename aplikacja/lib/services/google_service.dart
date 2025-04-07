import 'package:google_sign_in/google_sign_in.dart';

class GoogleService {
  static Future<GoogleSignInAccount?> googleSignIn() async {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: <String>[
        'email',
      ],
    );

    await googleSignIn.signOut();

    var googleUser = await googleSignIn.signIn();

    print(googleUser.toString());

    return googleUser;
  }

  static Future<void> _registerGoogleUser(GoogleSignInAccount googleUser) async {
      final name = googleUser.displayName!.contains(" ") ? googleUser.displayName?.split(" ")[0] : googleUser.displayName;
      final surname = googleUser.displayName!.contains(" ") ? googleUser.displayName?.split(" ")[1] : "";
      final age = 0;
      final userNickname = googleUser.displayName;
      final email = googleUser.email;
      final password = googleUser.id;

  }
}