# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: src/third_party/chromiumos-overlay/proto/design_variant_config.proto

import sys
_b=sys.version_info[0]<3 and (lambda x:x) or (lambda x:x.encode('latin1'))
from google.protobuf import descriptor as _descriptor
from google.protobuf import message as _message
from google.protobuf import reflection as _reflection
from google.protobuf import symbol_database as _symbol_database
# @@protoc_insertion_point(imports)

_sym_db = _symbol_database.Default()


from src.third_party.chromiumos_overlay.proto import audio_config_pb2 as src_dot_third__party_dot_chromiumos__overlay_dot_proto_dot_audio__config__pb2
from src.third_party.chromiumos_overlay.proto import firmware_config_pb2 as src_dot_third__party_dot_chromiumos__overlay_dot_proto_dot_firmware__config__pb2
from src.platform2.bluetooth.proto import config_pb2 as src_dot_platform2_dot_bluetooth_dot_proto_dot_config__pb2
from src.platform2.chromeos_config.proto import design_variant_id_scan_config_pb2 as src_dot_platform2_dot_chromeos__config_dot_proto_dot_design__variant__id__scan__config__pb2
from src.platform2.power_manager import config_pb2 as src_dot_platform2_dot_power__manager_dot_config__pb2


DESCRIPTOR = _descriptor.FileDescriptor(
  name='src/third_party/chromiumos-overlay/proto/design_variant_config.proto',
  package='chromiumos_overlay',
  syntax='proto3',
  serialized_options=None,
  serialized_pb=_b('\nDsrc/third_party/chromiumos-overlay/proto/design_variant_config.proto\x12\x12\x63hromiumos_overlay\x1a;src/third_party/chromiumos-overlay/proto/audio_config.proto\x1a>src/third_party/chromiumos-overlay/proto/firmware_config.proto\x1a*src/platform2/bluetooth/proto/config.proto\x1aGsrc/platform2/chromeos-config/proto/design_variant_id_scan_config.proto\x1a(src/platform2/power_manager/config.proto\"\xb0\x02\n\x13\x44\x65signVariantConfig\x12?\n\x0bscan_config\x18\x01 \x01(\x0b\x32*.chromeos_config.DesignVariantIdScanConfig\x12*\n\x08\x66irmware\x18\x02 \x01(\x0b\x32\x18.firmware.FirmwareConfig\x12\x34\n\x10\x62luetooth_config\x18\x03 \x01(\x0b\x32\x1a.bluetooth.BluetoothConfig\x12?\n\x14power_manager_config\x18\x04 \x01(\x0b\x32!.power_manager.PowerManagerConfig\x12\x35\n\x0c\x61udio_config\x18\x05 \x01(\x0b\x32\x1f.chromiumos_overlay.AudioConfigb\x06proto3')
  ,
  dependencies=[src_dot_third__party_dot_chromiumos__overlay_dot_proto_dot_audio__config__pb2.DESCRIPTOR,src_dot_third__party_dot_chromiumos__overlay_dot_proto_dot_firmware__config__pb2.DESCRIPTOR,src_dot_platform2_dot_bluetooth_dot_proto_dot_config__pb2.DESCRIPTOR,src_dot_platform2_dot_chromeos__config_dot_proto_dot_design__variant__id__scan__config__pb2.DESCRIPTOR,src_dot_platform2_dot_power__manager_dot_config__pb2.DESCRIPTOR,])




_DESIGNVARIANTCONFIG = _descriptor.Descriptor(
  name='DesignVariantConfig',
  full_name='chromiumos_overlay.DesignVariantConfig',
  filename=None,
  file=DESCRIPTOR,
  containing_type=None,
  fields=[
    _descriptor.FieldDescriptor(
      name='scan_config', full_name='chromiumos_overlay.DesignVariantConfig.scan_config', index=0,
      number=1, type=11, cpp_type=10, label=1,
      has_default_value=False, default_value=None,
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      serialized_options=None, file=DESCRIPTOR),
    _descriptor.FieldDescriptor(
      name='firmware', full_name='chromiumos_overlay.DesignVariantConfig.firmware', index=1,
      number=2, type=11, cpp_type=10, label=1,
      has_default_value=False, default_value=None,
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      serialized_options=None, file=DESCRIPTOR),
    _descriptor.FieldDescriptor(
      name='bluetooth_config', full_name='chromiumos_overlay.DesignVariantConfig.bluetooth_config', index=2,
      number=3, type=11, cpp_type=10, label=1,
      has_default_value=False, default_value=None,
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      serialized_options=None, file=DESCRIPTOR),
    _descriptor.FieldDescriptor(
      name='power_manager_config', full_name='chromiumos_overlay.DesignVariantConfig.power_manager_config', index=3,
      number=4, type=11, cpp_type=10, label=1,
      has_default_value=False, default_value=None,
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      serialized_options=None, file=DESCRIPTOR),
    _descriptor.FieldDescriptor(
      name='audio_config', full_name='chromiumos_overlay.DesignVariantConfig.audio_config', index=4,
      number=5, type=11, cpp_type=10, label=1,
      has_default_value=False, default_value=None,
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      serialized_options=None, file=DESCRIPTOR),
  ],
  extensions=[
  ],
  nested_types=[],
  enum_types=[
  ],
  serialized_options=None,
  is_extendable=False,
  syntax='proto3',
  extension_ranges=[],
  oneofs=[
  ],
  serialized_start=377,
  serialized_end=681,
)

_DESIGNVARIANTCONFIG.fields_by_name['scan_config'].message_type = src_dot_platform2_dot_chromeos__config_dot_proto_dot_design__variant__id__scan__config__pb2._DESIGNVARIANTIDSCANCONFIG
_DESIGNVARIANTCONFIG.fields_by_name['firmware'].message_type = src_dot_third__party_dot_chromiumos__overlay_dot_proto_dot_firmware__config__pb2._FIRMWARECONFIG
_DESIGNVARIANTCONFIG.fields_by_name['bluetooth_config'].message_type = src_dot_platform2_dot_bluetooth_dot_proto_dot_config__pb2._BLUETOOTHCONFIG
_DESIGNVARIANTCONFIG.fields_by_name['power_manager_config'].message_type = src_dot_platform2_dot_power__manager_dot_config__pb2._POWERMANAGERCONFIG
_DESIGNVARIANTCONFIG.fields_by_name['audio_config'].message_type = src_dot_third__party_dot_chromiumos__overlay_dot_proto_dot_audio__config__pb2._AUDIOCONFIG
DESCRIPTOR.message_types_by_name['DesignVariantConfig'] = _DESIGNVARIANTCONFIG
_sym_db.RegisterFileDescriptor(DESCRIPTOR)

DesignVariantConfig = _reflection.GeneratedProtocolMessageType('DesignVariantConfig', (_message.Message,), dict(
  DESCRIPTOR = _DESIGNVARIANTCONFIG,
  __module__ = 'src.third_party.chromiumos_overlay.proto.design_variant_config_pb2'
  # @@protoc_insertion_point(class_scope:chromiumos_overlay.DesignVariantConfig)
  ))
_sym_db.RegisterMessage(DesignVariantConfig)


# @@protoc_insertion_point(module_scope)
