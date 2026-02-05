import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'SUPABASE_URL')
  static const String supabaseUrl = _Env.supabaseUrl;

  @EnviedField(varName: 'SUPABASE_ANON_KEY')
  static const String supabaseAnonKey = _Env.supabaseAnonKey;

  @EnviedField(varName: 'OPENAI_API_KEY', obfuscate: true)
  static final String openaiApiKey = _Env.openaiApiKey;

  @EnviedField(varName: 'ELEVENLABS_API_KEY', obfuscate: true)
  static final String elevenlabsApiKey = _Env.elevenlabsApiKey;

  @EnviedField(varName: 'ELEVENLABS_VOICE_ID')
  static const String elevenlabsVoiceId = _Env.elevenlabsVoiceId;

  @EnviedField(varName: 'ELEVENLABS_AGENT_ID')
  static const String elevenlabsAgentId = _Env.elevenlabsAgentId;
}

