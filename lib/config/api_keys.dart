import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiKeys {
  ApiKeys._();

  static const String openRouterApiKey =
      String.fromEnvironment('OPENROUTER_API_KEY');

  static const String supabaseUrl =
      "https://dtivhpgswchkjvwvjujd.supabase.co/rest/v1/";

  static const String supabaseAnonKey =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR0aXZocGdzd2Noa2p2d3ZqdWpkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI5OTg0NTYsImV4cCI6MjA5ODU3NDQ1Nn0.B1SZHL8Du5QNh8VaKDsEXxK104wswSiuH6mGInrBqog";
}