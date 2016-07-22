//
//  OBDSensors.h
//  OBD2Kit
//
//  Created by Alko on 13/11/13.
//
//

/**
 Supported OBD2 sensors list
 For detailed information read https://en.wikipedia.org/wiki/OBD-II_PIDs
*/

typedef NS_ENUM(NSUInteger, OBD2Sensor) {
    OBD2SensorPIDsSupported01_20 = 0x00,
    OBD2SensorMonitorStatusSinceDTCsCleared = 0x01,
    OBD2SensorFreezeFrameStatus = 0x02,
    OBD2SensorFuelSystemStatus = 0x03,
    OBD2SensorCalculatedEngineLoadValue = 0x04,
    OBD2SensorEngineCoolantTemperature = 0x05,
    OBD2SensorShorttermfueltrimBank1 = 0x06,
    OBD2SensorLongtermfueltrimBank1 = 0x07,
    OBD2SensorShorttermfueltrimBank2 = 0x08,
    OBD2SensorLongtermfueltrimBank2 = 0x09,
    OBD2SensorFuelPressure = 0x0A,
    OBD2SensorIntakeManifoldPressure = 0x0B,
    OBD2SensorEngineRPM = 0x0C,
    OBD2SensorVehicleSpeed = 0x0D,
    OBD2SensorTimingAdvance = 0x0E,
    OBD2SensorIntakeAirTemperature = 0x0F,
    OBD2SensorMassAirFlow = 0x10,
    OBD2SensorThrottlePosition = 0x11,
    OBD2SensorSecondaryAirStatus = 0x12,
    OBD2SensorOxygenSensorsPresent = 0x13,
    OBD2SensorOxygenVoltageBank1Sensor1 = 0x14,
    OBD2SensorOxygenVoltageBank1Sensor2 = 0x15,
    OBD2SensorOxygenVoltageBank1Sensor3 = 0x16,
    OBD2SensorOxygenVoltageBank1Sensor4 = 0x17,
    OBD2SensorOxygenVoltageBank2Sensor1 = 0x18,
    OBD2SensorOxygenVoltageBank2Sensor2 = 0x19,
    OBD2SensorOxygenVoltageBank2Sensor3 = 0x1A,
    OBD2SensorOxygenVoltageBank2Sensor4 = 0x1B,
    OBD2SensorOBDStandardsThisVehicleConforms = 0x1C,
    OBD2SensorOxygenSensorsPresent2 = 0x1D,
    OBD2SensorAuxiliaryInputStatus = 0x1E,
    OBD2SensorRunTimeSinceEngineStart = 0x1F,
    OBD2SensorPIDsSupported21_40 = 0x20,
    OBD2SensorDistanceTraveledWithMalfunctionIndicatorLampOn = 0x21,
    OBD2SensorFuelRailPressureManifoldVacuum = 0x22,
    OBD2SensorFuelRailPressureDiesel = 0x23,
    OBD2SensorEquivalenceRatioVoltageO2S1 = 0x24,
    OBD2SensorEquivalenceRatioVoltageO2S2 = 0x25,
    OBD2SensorEquivalenceRatioVoltageO2S3 = 0x26,
    OBD2SensorEquivalenceRatioVoltageO2S4 = 0x27,
    OBD2SensorEquivalenceRatioVoltageO2S5 = 0x28,
    OBD2SensorEquivalenceRatioVoltageO2S6 = 0x29,
    OBD2SensorEquivalenceRatioVoltageO2S7 = 0x2A,
    OBD2SensorEquivalenceRatioVoltageO2S8 = 0x2B,
    OBD2SensorCommandedEGR = 0x2C,
    OBD2SensorEGRError = 0x2D,
    OBD2SensorCommandedEvaporativePurge = 0x2E,
    OBD2SensorFuelLevelInput = 0x2F,
    OBD2SensorNumberofWarmUpsSinceCodesCleared = 0x30,
    OBD2SensorDistanceTraveledSinceCodesCleared = 0x31,
    OBD2SensorEvaporativeSystemVaporPressure = 0x32,
    OBD2SensorBarometricPressure = 0x33,
    OBD2SensorEquivalenceRatioCurrentO2S1 = 0x34,
    OBD2SensorEquivalenceRatioCurrentO2S2 = 0x35,
    OBD2SensorEquivalenceRatioCurrentO2S3 = 0x36,
    OBD2SensorEquivalenceRatioCurrentO2S4 = 0x37,
    OBD2SensorEquivalenceRatioCurrentO2S5 = 0x38,
    OBD2SensorEquivalenceRatioCurrentO2S6 = 0x39,
    OBD2SensorEquivalenceRatioCurrentO2S7 = 0x3A,
    OBD2SensorEquivalenceRatioCurrentO2S8 = 0x3B,
    OBD2SensorCatalystTemperatureBank1Sensor1 = 0x3C,
    OBD2SensorCatalystTemperatureBank2Sensor1 = 0x3D,
    OBD2SensorCatalystTemperatureBank1Sensor2 = 0x3E,
    OBD2SensorCatalystTemperatureBank2Sensor2 = 0x3F,
    OBD2SensorPIDsSupported41_60 = 0x40,
    OBD2SensorMonitorStatusThisDriveCycle = 0x41,
    OBD2SensorControlModuleVoltage = 0x42,
    OBD2SensorAbsoluteLoadValue = 0x43,
    OBD2SensorCommandEquivalenceRatio = 0x44,
    OBD2SensorRelativeThrottlePosition = 0x45,
    OBD2SensorAmbientAirTemperature = 0x46,
    OBD2SensorAbsoluteThrottlePositionB = 0x47,
    OBD2SensorAbsoluteThrottlePositionC = 0x48,
    OBD2SensorAcceleratorPedalPositionD = 0x49,
    OBD2SensorAcceleratorPedalPositionE = 0x4A,
    OBD2SensorAcceleratorPedalPositionF = 0x4B,
    OBD2SensorCommandedThrottleActuator = 0x4C,
    OBD2SensorTimeRunWithMILOn = 0x4D,
    OBD2SensorTimeSinceTroubleCodesCleared = 0x4E,
    
    // From this point sensors don't have full support yet
    OBD2SensorMaxValueForER_OSV_OSC_IMAP = 0x4F,    /* Maximum value for equivalence ratio, oxygen sensor voltage,
                                                     oxygen sensor current and intake manifold absolute pressure
                                                     */
    OBD2SensorMaxValueForAirFlowRateFromMAFSensor = 0x50,
    OBD2SensorFuelType = 0x51,
    OBD2SensorEthanolFuelRatio = 0x52,
    OBD2SensorAbsoluteEvapSystemVaporPressure = 0x53,
    OBD2SensorEvapSystemVaporPressure = 0x54,
    OBD2SensorShortTermSecondaryOxygenSensorTrimBank_1_3 = 0x55,
    OBD2SensorLongTermSecondaryOxygenSensorTrimBank_1_3 = 0x56,
    OBD2SensorrShortTermSecondaryOxygenSensorTrimBank_2_4 = 0x57,
    OBD2SensorLongTermSecondaryOxygenSensorTrimBank_2_4 = 0x58,
    OBD2SensorFuelRailPressure_Absolute = 0x59,
    OBD2SensorRelativeAcceleratorPedalPosition = 0x5A,
    OBD2SensorHybridBatteryPackRemainingLife = 0x5B,
    OBD2SensorEngineOilTemperature = 0x5C,
    
//    OBD2Sensor = 0x,
// Sensors should be added at this point for supporting count and last.
    
    OBD2SensorsSupportedCount,
    };

#define OBD2SensorLast OBD2SensorsSupportedCount - 1
