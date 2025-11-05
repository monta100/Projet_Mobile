import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:translator/translator.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'physical_activities_main_screen.dart';

const Color mainGreen = Color(0xFF2ECC71);
const Color darkGreen = Color(0xFF1E8449);

class ActivitiesHomeScreen extends StatefulWidget {
  const ActivitiesHomeScreen({super.key});

  @override
  State<ActivitiesHomeScreen> createState() => _ActivitiesHomeScreenState();
}

class _ActivitiesHomeScreenState extends State<ActivitiesHomeScreen> {
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

  // --- 🌍 Demander la permission de géolocalisation ---
  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Les services de localisation sont désactivés. Veuillez les activer.',
          ),
        ),
      );
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission de localisation refusée')),
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Les permissions de localisation sont définitivement refusées',
          ),
        ),
      );
      return false;
    }

    return true;
  }

  // --- 🌍 API Météo avec géolocalisation ---
  Future<void> _getWeather() async {
    try {
      final hasPermission = await _handleLocationPermission();
      if (!hasPermission) {
        // Utiliser une position par défaut si pas de permission
        setState(() {
          _city = "Position inconnue";
          _temp = 20;
          _weatherDesc = "météo non disponible";
        });
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      print(
        "📍 Position actuelle : ${position.latitude}, ${position.longitude}",
      );

      // Obtenir le nom exact de la ville avec le géocodage inverse
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        _city =
            place.locality ?? place.subAdministrativeArea ?? "Ville inconnue";
      }

      final url = Uri.parse(
        "https://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&appid=$_weatherKey&units=metric&lang=fr",
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
        setState(() {
          _city = "Tunis";
          _temp = 25;
          _weatherDesc = "ciel dégagé";
        });
      }
    } catch (e) {
      print("❌ Erreur météo : $e");
      setState(() {
        _city = "Tunis";
        _temp = 25;
        _weatherDesc = "ciel dégagé";
      });
    }
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
    if (_temp! >= 25)
      return "☀️ ${_temp!.round()}°C - Idéal pour courir dehors !";
    if (_temp! < 15)
      return "❄️ ${_temp!.round()}°C - Entraîne-toi en intérieur 🔥";
    if (_weatherDesc.contains("pluie"))
      return "🌧️ Pluie - Opte pour une séance indoor.";
    return "💪 ${_temp!.round()}°C - Conditions parfaites pour bouger !";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: mainGreen))
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 30,
                    ),
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

                        // --- 🚀 Bouton Explorer ---
                        ElevatedButton.icon(
                          onPressed: () {
                            // Naviguer vers l'écran des activités physiques avec la barre de navigation
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const PhysicalActivitiesMainScreen(),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.fitness_center,
                            color: Colors.white,
                          ),
                          label: const Text("Explorer mes activités"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: mainGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 14,
                            ),
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
    if (desc.contains("soleil") || desc.contains("dégagé"))
      return Icons.wb_sunny;
    return Icons.wb_cloudy;
  }
}
