import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:translator/translator.dart';
import 'package:geolocator/geolocator.dart';
import '../Entites/utilisateur.dart';
import 'activity_navigation_screen.dart';

// Couleurs du module activité physique
const Color mainGreen = Color(0xFF43A047);
const Color darkGreen = Color(0xFF2E7D32);

/// 🏃‍♂️ Écran de bienvenue du module Activité Physique
/// Affiche la météo de votre localisation GPS et une citation motivante traduite en français
class ActivityWelcomeScreen extends StatefulWidget {
  final Utilisateur utilisateur;

  const ActivityWelcomeScreen({Key? key, required this.utilisateur}) : super(key: key);

  @override
  State<ActivityWelcomeScreen> createState() => _ActivityWelcomeScreenState();
}

class _ActivityWelcomeScreenState extends State<ActivityWelcomeScreen> {
  String _city = "";
  double? _temp;
  String _weatherDesc = "";
  String _quote = "";
  bool _loading = true;

  static const String _weatherKey = "5fd0004d433043c4aed98c1defc9528d";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _getWeather();
    await _getQuote();
    setState(() => _loading = false);
  }

  // --- 🌍 API Météo avec localisation GPS + IP Fallback ---
  Future<void> _getWeather() async {
    try {
      // 🔒 Vérifier les permissions de localisation
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print("⚠️ Permission de localisation refusée - Utilisation géolocalisation IP");
          await _getWeatherByIP();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print("⚠️ Permission de localisation refusée définitivement - Utilisation géolocalisation IP");
        await _getWeatherByIP();
        return;
      }

      // 📍 Obtenir la position GPS actuelle (réelle ou émulateur configuré)
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );

      final latitude = position.latitude;
      final longitude = position.longitude;

      print("📍 Localisation GPS : $latitude, $longitude");

      // ✅ Utiliser la position GPS (que ce soit un vrai téléphone ou émulateur configuré)
      await _getWeatherByCoordinates(latitude, longitude);
    } catch (e) {
      print("❌ Erreur GPS : $e - Tentative géolocalisation IP");
      await _getWeatherByIP();
    }
  }

  // 🌐 Géolocalisation par IP (pour émulateur et fallback)
  Future<void> _getWeatherByIP() async {
    try {
      // API de géolocalisation IP gratuite
      final ipUrl = Uri.parse("http://ip-api.com/json/?fields=lat,lon,city");
      final ipRes = await http.get(ipUrl);
      
      if (ipRes.statusCode == 200) {
        final ipData = json.decode(ipRes.body);
        final latitude = ipData["lat"];
        final longitude = ipData["lon"];
        
        print("📍 Localisation IP : $latitude, $longitude (${ipData["city"]})");
        await _getWeatherByCoordinates(latitude, longitude);
      } else {
        _setDefaultWeather();
      }
    } catch (e) {
      print("❌ Erreur géolocalisation IP : $e");
      _setDefaultWeather();
    }
  }

  // 🌤️ Récupérer la météo par coordonnées
  Future<void> _getWeatherByCoordinates(double latitude, double longitude) async {
    try {
      final url = Uri.parse(
        "https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&appid=$_weatherKey&units=metric&lang=fr",
      );

      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          _city = data["name"];
          _temp = data["main"]["temp"].toDouble();
          _weatherDesc = data["weather"][0]["description"];
        });
      } else {
        _setDefaultWeather();
      }
    } catch (e) {
      print("❌ Erreur API météo : $e");
      _setDefaultWeather();
    }
  }

  // Fallback si tout échoue
  void _setDefaultWeather() {
    setState(() {
      _city = "Localisation indisponible";
      _temp = 20;
      _weatherDesc = "temps agréable";
    });
  }

  // --- 💬 API Citations + traduction française ---
  Future<void> _getQuote() async {
    try {
      final url = Uri.parse("https://zenquotes.io/api/random");
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        String quote = data[0]["q"] + " — " + data[0]["a"];

        // Traduction automatique 🇫🇷
        final translator = GoogleTranslator();
        var translation = await translator.translate(quote, to: 'fr');
        setState(() => _quote = translation.text);
      } else {
        _quote = "Le corps accomplit ce que l'esprit croit 💫";
      }
    } catch (_) {
      _quote = "Fais un pas aujourd'hui, ton futur te remerciera 🌟";
    }
  }

  // --- 🏋️ Message de motivation selon météo ---
  String _getMotivation() {
    if (_temp == null) return "Prépare-toi à t'entraîner ! 💪";
    if (_temp! >= 25) return "☀️ ${_temp!.round()}°C - Idéal pour courir dehors !";
    if (_temp! < 15) return "❄️ ${_temp!.round()}°C - Entraîne-toi en intérieur 🔥";
    if (_weatherDesc.contains("pluie")) return "🌧️ Pluie - Opte pour une séance indoor.";
    return "💪 ${_temp!.round()}°C - Conditions parfaites pour bouger !";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: mainGreen),
              )
            : Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFE8F8F5), Color(0xFFD1F2EB)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // --- 📦 Carte météo ---
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Icon(
                                _getWeatherIcon(_weatherDesc),
                                color: mainGreen,
                                size: 70,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _city,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: darkGreen,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "${_temp?.toStringAsFixed(1) ?? '--'}°C",
                                style: const TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w700,
                                  color: mainGreen,
                                ),
                              ),
                              Text(
                                _weatherDesc,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),

                        // --- 💪 Message météo ---
                        Text(
                          _getMotivation(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 30),

                        // --- 💭 Citation ---
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            "💭 $_quote",
                            style: const TextStyle(
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 50),

                        // --- 🚀 Bouton Continuer ---
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ActivityNavigationScreen(
                                  utilisateur: widget.utilisateur,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.arrow_forward, color: Colors.white),
                          label: const Text("Continuer vers l'application"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: mainGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            elevation: 6,
                            shadowColor: mainGreen.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  // --- 🌤️ Icône météo dynamique ---
  IconData _getWeatherIcon(String desc) {
    if (desc.contains("nuage")) return Icons.cloud;
    if (desc.contains("pluie")) return Icons.umbrella;
    if (desc.contains("orage")) return Icons.bolt;
    if (desc.contains("neige")) return Icons.ac_unit;
    if (desc.contains("soleil") || desc.contains("dégagé")) return Icons.wb_sunny;
    return Icons.wb_cloudy;
  }
}

