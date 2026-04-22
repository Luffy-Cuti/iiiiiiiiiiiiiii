sealed class LoginEvent {
  const LoginEvent();
}

class EmailChanged extends LoginEvent {
  const EmailChanged(this.value);

  final String value;
}

class PasswordChanged extends LoginEvent {
  const PasswordChanged(this.value);

  final String value;
}

class RememberMeChanged extends LoginEvent {
  const RememberMeChanged(this.value);

  final bool value;
}

class PasswordVisibilityToggled extends LoginEvent {
  const PasswordVisibilityToggled();
}

class LoginSubmitted extends LoginEvent {
  const LoginSubmitted();
}

class GoogleLoginTapped extends LoginEvent {
  const GoogleLoginTapped();
}
