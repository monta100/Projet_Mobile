import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:translator/translator.dart';
import '../main.dart'; // pour accéder à MyHomePage

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

  // --- 🌍 API Météo forcée sur Tunis ---
  Future<void> _getWeather() async {
    try {
      // Localisation forcée : Tunis 🇹🇳
      const double latitude = 36.8065;
      const double longitude = 10.1815;

      print("📍 Localisation forcée : $latitude, $longitude (Tunis)");

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
        _quote = "Le corps accomplit ce que l’esprit croit 💫";
      }
    } catch (_) {
      _quote = "Fais un pas aujourd’hui, ton futur te remerciera 🌟";
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
                              MaterialPageRoute(builder: (_) => const MyHomePage()),
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
