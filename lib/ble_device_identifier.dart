import 'dart:math' as Math;

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'mac_address_lookup.dart';

class BleDeviceIdentifier {
  // Get device name with multi-layer fallback strategy
  static String getDeviceName(ScanResult result) {
    final device = result.device;
    final advData = result.advertisementData;
    final macAddress = device.remoteId.str;
    
    // Priority 1: Platform name from Flutter Blue Plus
    if (device.platformName.isNotEmpty) {
      return device.platformName;
    }
    
    // Priority 2: Advertisement data local name
    if (advData.advName.isNotEmpty) {
      return advData.advName;
    }
    
    // Priority 3: Manufacturer data lookup
    final manufacturerName = _getManufacturerFromData(advData.manufacturerData);
    if (manufacturerName != null) {
      return "$manufacturerName Device (${_formatMacShort(macAddress)})";
    }
    
    // Priority 4: MAC address lookup
    final macManufacturer = MacAddressLookup.lookupManufacturer(macAddress);
    if (macManufacturer != null) {
      return "$macManufacturer Device (${_formatMacShort(macAddress)})";
    }
    
    // Priority 5: Fallback to Unknown Device with MAC
    return "Unknown Device (${_formatMacShort(macAddress)})";
  }
  
  // Format MAC address to shorter form for display
  static String _formatMacShort(String macAddress) {
    // If it's already in XX:XX:XX format, return as is
    if (macAddress.contains(':')) {
      final parts = macAddress.split(':');
      if (parts.length >= 3) {
        return "${parts[parts.length - 3]}:${parts[parts.length - 2]}:${parts[parts.length - 1]}";
      }
    }
    
    // If it's in another format or can't be parsed, return as is
    return macAddress.substring(Math.max(0, macAddress.length - 8));
  }
  
  // Extract manufacturer name from manufacturer data
  static String? _getManufacturerFromData(Map<int, List<int>> manufacturerData) {
    if (manufacturerData.isEmpty) return null;
    
    // Common manufacturer IDs
    const Map<int, String> manufacturerIds = {
      0x004C: 'Apple',      // Apple
      0x0075: 'Samsung',    // Samsung
      0x0059: 'Google',     // Google
      0x0046: 'Sony',       // Sony Mobile
      0x038F: 'Xiaomi',     // Xiaomi
      0x0157: 'boAt',       // boAt
      0x01D7: 'Bose',       // Bose
      0x0001: 'Nokia',      // Nokia
      0x0002: 'Intel',      // Intel
      0x0003: 'IBM',        // IBM
      0x0004: 'Toshiba',    // Toshiba
      0x0005: 'Ericsson',   // Ericsson
      0x0006: 'Microsoft',  // Microsoft
      0x000A: 'CSR',        // CSR (Cambridge Silicon Radio)
      0x000C: 'Motorola',   // Motorola
      0x000E: 'Broadcom',   // Broadcom
      0x000F: 'TI',         // Texas Instruments
      0x0010: 'Marvell',    // Marvell
      0x0012: 'Qualcomm',   // Qualcomm
      0x0037: 'Huawei',     // Huawei
      0x0078: 'OnePlus',    // OnePlus
      0x0090: 'Realme',     // Realme
      0x00E0: 'Oppo',       // Oppo
      0x00F0: 'Vivo',       // Vivo
      0x0131: 'Lenovo',     // Lenovo
      0x0156: 'Amazon',     // Amazon
      0x0184: 'LG',         // LG Electronics
      0x01A8: 'Fitbit',     // Fitbit
      0x01AD: 'Garmin',     // Garmin
      0x01BF: 'Fossil',     // Fossil
      0x01D4: 'Skullcandy', // Skullcandy
      0x01E8: 'Jabra',      // Jabra
      0x01F4: 'JBL',        // JBL
      0x0200: 'Sennheiser', // Sennheiser
      0x0201: 'Plantronics',// Plantronics
      0x0202: 'Beats',      // Beats Electronics
      0x0203: 'Anker',      // Anker
      0x0204: 'Jaybird',    // Jaybird
      0x0205: 'Logitech',   // Logitech
      0x0206: 'Razer',      // Razer
      0x0207: 'SteelSeries',// SteelSeries
      0x0208: 'Corsair',    // Corsair
      0x0209: 'HyperX',     // HyperX
      0x020A: 'Turtle Beach',// Turtle Beach
      0x020B: 'Astro',      // Astro Gaming
      0x020C: 'Ultimate Ears',// Ultimate Ears
      0x020D: 'Marshall',   // Marshall
      0x020E: 'Audio-Technica',// Audio-Technica
      0x020F: 'Bang & Olufsen',// Bang & Olufsen
      0x0210: 'Harman Kardon',// Harman Kardon
      0x0211: 'AKG',        // AKG
      0x0212: 'Philips',    // Philips
      0x0213: 'Panasonic',  // Panasonic
      0x0214: 'Pioneer',    // Pioneer
      0x0215: 'Yamaha',     // Yamaha
      0x0216: 'Denon',      // Denon
      0x0217: 'Marantz',    // Marantz
      0x0218: 'Sonos',      // Sonos
      0x0219: 'Bowers & Wilkins',// Bowers & Wilkins
      0x021A: 'Klipsch',    // Klipsch
      0x021B: 'Polk Audio', // Polk Audio
      0x021C: 'Definitive Technology',// Definitive Technology
      0x021D: 'KEF',        // KEF
      0x021E: 'Focal',      // Focal
      0x021F: 'Edifier',    // Edifier
      0x0220: 'Creative',   // Creative
      0x0221: 'Anker Soundcore',// Anker Soundcore
      0x0222: 'Taotronics', // Taotronics
      0x0223: 'Mpow',       // Mpow
      0x0224: 'Aukey',      // Aukey
      0x0225: 'Tribit',     // Tribit
      0x0226: '1More',      // 1More
      0x0227: 'Earfun',     // Earfun
      0x0228: 'Tronsmart',  // Tronsmart
      0x0229: 'Soundpeats', // Soundpeats
      0x022A: 'Tozo',       // Tozo
      0x022B: 'Raycon',     // Raycon
      0x022C: 'Skullcandy', // Skullcandy
      0x022D: 'House of Marley',// House of Marley
      0x022E: 'Master & Dynamic',// Master & Dynamic
      0x022F: 'Grado',      // Grado
      0x0230: 'Shure',      // Shure
      0x0231: 'Beyerdynamic',// Beyerdynamic
      0x0232: 'Audeze',     // Audeze
      0x0233: 'HiFiMan',    // HiFiMan
      0x0234: 'Campfire Audio',// Campfire Audio
      0x0235: 'FiiO',       // FiiO
      0x0236: 'RHA',        // RHA
      0x0237: 'Westone',    // Westone
      0x0238: 'Etymotic',   // Etymotic
      0x0239: 'Final Audio',// Final Audio
      0x023A: 'Moondrop',   // Moondrop
      0x023B: 'KZ',         // KZ Acoustics
      0x023C: 'TIN Audio',  // TIN Audio
      0x023D: 'BLON',       // BLON
      0x023E: 'CCA',        // CCA
      0x023F: 'TRN',        // TRN
      0x0240: 'IKKO',       // IKKO
      0x0241: 'Shozy',      // Shozy
      0x0242: 'ThieAudio',  // ThieAudio
      0x0243: 'Fearless Audio',// Fearless Audio
      0x0244: 'Simgot',     // Simgot
      0x0245: 'BGVP',       // BGVP
      0x0246: 'Tanchjim',   // Tanchjim
      0x0247: 'Shanling',   // Shanling
      0x0248: 'iBasso',     // iBasso
      0x0249: 'Hiby',       // Hiby
      0x024A: 'Cayin',      // Cayin
      0x024B: 'Qudelix',    // Qudelix
      0x024C: 'EarStudio',  // EarStudio
      0x024D: 'Hidizs',     // Hidizs
      0x024E: 'Tempotec',   // Tempotec
      0x024F: 'SMSL',       // SMSL
      0x0250: 'Topping',    // Topping
      0x0251: 'JDS Labs',   // JDS Labs
      0x0252: 'Schiit',     // Schiit
      0x0253: 'Drop',       // Drop (formerly Massdrop)
      0x0254: 'Monoprice',  // Monoprice
      0x0255: 'Hifiman',    // Hifiman
    };
    
    // Try to get manufacturer ID from the data
    final manufacturerId = manufacturerData.keys.first;
    return manufacturerIds[manufacturerId];
  }
}