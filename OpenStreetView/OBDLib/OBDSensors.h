//
//  OBDSensors.h
//  OBDLib
//
//  Created by BogdanB on 24/03/16.
//  Copyright © 2016 Telenav. All rights reserved.
//

typedef NS_ENUM(uint16_t, OBDSensor) {
    //Mode 01
    OBDSensorSupportedPID01_20            = 0x0100,
    OBDSensorMonitorStatusSinceDTCClear   = 0x0101,
    OBDSensorFreezeDTC                    = 0x0102,
    OBDSensorFuelSystemStatus             = 0x0103,
    OBDSensorCalculatedEngineLoad         = 0x0104,
    OBDSensorEngineCoolantTemp            = 0x0105,
    OBDSensorShortTermFuelTrimBank1       = 0x0106,
    OBDSensorLongTermFuelTrimBank1        = 0x0107,
    OBDSensorShortTermFuelTrimBank2       = 0x0108,
    OBDSensorLongTermFuelTrimBank2        = 0x0109,
    OBDSensorFuelPressure                 = 0x010A,
    OBDSensorIntakeManifoldAbsPressure    = 0x010B,
    OBDSensorEngineRPM                    = 0x010C, // Integer 0 - 16383
    OBDSensorVehicleSpeed                 = 0x010D, // Integer 0 - 255
    OBDSensorTimingAdvance                = 0x010E,
    OBDSensorIntakeAirTemp                = 0x010F,
    OBDSensorMAFAirFlow                   = 0x0110,
    OBDSensorThrottlePosition             = 0x0111,
    OBDSensorUnknown                      = 0xFFFF
};
