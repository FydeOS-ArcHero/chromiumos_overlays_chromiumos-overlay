# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: src/third_party/chromiumos-overlay/proto/firmware_config.proto

import sys
_b=sys.version_info[0]<3 and (lambda x:x) or (lambda x:x.encode('latin1'))
from google.protobuf.internal import enum_type_wrapper
from google.protobuf import descriptor as _descriptor
from google.protobuf import message as _message
from google.protobuf import reflection as _reflection
from google.protobuf import symbol_database as _symbol_database
# @@protoc_insertion_point(imports)

_sym_db = _symbol_database.Default()


from chromite.infra.proto.src.chromiumos import common_pb2 as chromite_dot_infra_dot_proto_dot_src_dot_chromiumos_dot_common__pb2


DESCRIPTOR = _descriptor.FileDescriptor(
  name='src/third_party/chromiumos-overlay/proto/firmware_config.proto',
  package='firmware',
  syntax='proto3',
  serialized_options=_b('ZMgo.chromium.org/chromiumos/config/go/src/third_party/chromiumos-overlay/proto'),
  serialized_pb=_b('\n>src/third_party/chromiumos-overlay/proto/firmware_config.proto\x12\x08\x66irmware\x1a\x30\x63hromite/infra/proto/src/chromiumos/common.proto\"\'\n\x07Version\x12\r\n\x05major\x18\x01 \x01(\x05\x12\r\n\x05minor\x18\x02 \x01(\x05\"\xa7\x01\n\x0f\x46irmwarePayload\x12-\n\x0c\x62uild_target\x18\x01 \x01(\x0b\x32\x17.chromiumos.BuildTarget\x12\x1b\n\x13\x66irmware_image_name\x18\x02 \x01(\t\x12$\n\x04type\x18\x03 \x01(\x0e\x32\x16.firmware.FirmwareType\x12\"\n\x07version\x18\x04 \x01(\x0b\x32\x11.firmware.Version\"\xaa\x01\n\x0e\x46irmwareConfig\x12\x32\n\x0fmain_ro_payload\x18\x01 \x01(\x0b\x32\x19.firmware.FirmwarePayload\x12\x32\n\x0fmain_rw_payload\x18\x02 \x01(\x0b\x32\x19.firmware.FirmwarePayload\x12\x30\n\rec_ro_payload\x18\x03 \x01(\x0b\x32\x19.firmware.FirmwarePayload*W\n\x0c\x46irmwareType\x12\x19\n\x15\x46IRMWARE_TYPE_UNKNOWN\x10\x00\x12\x16\n\x12\x46IRMWARE_TYPE_MAIN\x10\x01\x12\x14\n\x10\x46IRMWARE_TYPE_EC\x10\x02\x42OZMgo.chromium.org/chromiumos/config/go/src/third_party/chromiumos-overlay/protob\x06proto3')
  ,
  dependencies=[chromite_dot_infra_dot_proto_dot_src_dot_chromiumos_dot_common__pb2.DESCRIPTOR,])

_FIRMWARETYPE = _descriptor.EnumDescriptor(
  name='FirmwareType',
  full_name='firmware.FirmwareType',
  filename=None,
  file=DESCRIPTOR,
  values=[
    _descriptor.EnumValueDescriptor(
      name='FIRMWARE_TYPE_UNKNOWN', index=0, number=0,
      serialized_options=None,
      type=None),
    _descriptor.EnumValueDescriptor(
      name='FIRMWARE_TYPE_MAIN', index=1, number=1,
      serialized_options=None,
      type=None),
    _descriptor.EnumValueDescriptor(
      name='FIRMWARE_TYPE_EC', index=2, number=2,
      serialized_options=None,
      type=None),
  ],
  containing_type=None,
  serialized_options=None,
  serialized_start=510,
  serialized_end=597,
)
_sym_db.RegisterEnumDescriptor(_FIRMWARETYPE)

FirmwareType = enum_type_wrapper.EnumTypeWrapper(_FIRMWARETYPE)
FIRMWARE_TYPE_UNKNOWN = 0
FIRMWARE_TYPE_MAIN = 1
FIRMWARE_TYPE_EC = 2



_VERSION = _descriptor.Descriptor(
  name='Version',
  full_name='firmware.Version',
  filename=None,
  file=DESCRIPTOR,
  containing_type=None,
  fields=[
    _descriptor.FieldDescriptor(
      name='major', full_name='firmware.Version.major', index=0,
      number=1, type=5, cpp_type=1, label=1,
      has_default_value=False, default_value=0,
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      serialized_options=None, file=DESCRIPTOR),
    _descriptor.FieldDescriptor(
      name='minor', full_name='firmware.Version.minor', index=1,
      number=2, type=5, cpp_type=1, label=1,
      has_default_value=False, default_value=0,
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
  serialized_start=126,
  serialized_end=165,
)


_FIRMWAREPAYLOAD = _descriptor.Descriptor(
  name='FirmwarePayload',
  full_name='firmware.FirmwarePayload',
  filename=None,
  file=DESCRIPTOR,
  containing_type=None,
  fields=[
    _descriptor.FieldDescriptor(
      name='build_target', full_name='firmware.FirmwarePayload.build_target', index=0,
      number=1, type=11, cpp_type=10, label=1,
      has_default_value=False, default_value=None,
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      serialized_options=None, file=DESCRIPTOR),
    _descriptor.FieldDescriptor(
      name='firmware_image_name', full_name='firmware.FirmwarePayload.firmware_image_name', index=1,
      number=2, type=9, cpp_type=9, label=1,
      has_default_value=False, default_value=_b("").decode('utf-8'),
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      serialized_options=None, file=DESCRIPTOR),
    _descriptor.FieldDescriptor(
      name='type', full_name='firmware.FirmwarePayload.type', index=2,
      number=3, type=14, cpp_type=8, label=1,
      has_default_value=False, default_value=0,
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      serialized_options=None, file=DESCRIPTOR),
    _descriptor.FieldDescriptor(
      name='version', full_name='firmware.FirmwarePayload.version', index=3,
      number=4, type=11, cpp_type=10, label=1,
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
  serialized_start=168,
  serialized_end=335,
)


_FIRMWARECONFIG = _descriptor.Descriptor(
  name='FirmwareConfig',
  full_name='firmware.FirmwareConfig',
  filename=None,
  file=DESCRIPTOR,
  containing_type=None,
  fields=[
    _descriptor.FieldDescriptor(
      name='main_ro_payload', full_name='firmware.FirmwareConfig.main_ro_payload', index=0,
      number=1, type=11, cpp_type=10, label=1,
      has_default_value=False, default_value=None,
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      serialized_options=None, file=DESCRIPTOR),
    _descriptor.FieldDescriptor(
      name='main_rw_payload', full_name='firmware.FirmwareConfig.main_rw_payload', index=1,
      number=2, type=11, cpp_type=10, label=1,
      has_default_value=False, default_value=None,
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      serialized_options=None, file=DESCRIPTOR),
    _descriptor.FieldDescriptor(
      name='ec_ro_payload', full_name='firmware.FirmwareConfig.ec_ro_payload', index=2,
      number=3, type=11, cpp_type=10, label=1,
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
  serialized_start=338,
  serialized_end=508,
)

_FIRMWAREPAYLOAD.fields_by_name['build_target'].message_type = chromite_dot_infra_dot_proto_dot_src_dot_chromiumos_dot_common__pb2._BUILDTARGET
_FIRMWAREPAYLOAD.fields_by_name['type'].enum_type = _FIRMWARETYPE
_FIRMWAREPAYLOAD.fields_by_name['version'].message_type = _VERSION
_FIRMWARECONFIG.fields_by_name['main_ro_payload'].message_type = _FIRMWAREPAYLOAD
_FIRMWARECONFIG.fields_by_name['main_rw_payload'].message_type = _FIRMWAREPAYLOAD
_FIRMWARECONFIG.fields_by_name['ec_ro_payload'].message_type = _FIRMWAREPAYLOAD
DESCRIPTOR.message_types_by_name['Version'] = _VERSION
DESCRIPTOR.message_types_by_name['FirmwarePayload'] = _FIRMWAREPAYLOAD
DESCRIPTOR.message_types_by_name['FirmwareConfig'] = _FIRMWARECONFIG
DESCRIPTOR.enum_types_by_name['FirmwareType'] = _FIRMWARETYPE
_sym_db.RegisterFileDescriptor(DESCRIPTOR)

Version = _reflection.GeneratedProtocolMessageType('Version', (_message.Message,), dict(
  DESCRIPTOR = _VERSION,
  __module__ = 'src.third_party.chromiumos_overlay.proto.firmware_config_pb2'
  # @@protoc_insertion_point(class_scope:firmware.Version)
  ))
_sym_db.RegisterMessage(Version)

FirmwarePayload = _reflection.GeneratedProtocolMessageType('FirmwarePayload', (_message.Message,), dict(
  DESCRIPTOR = _FIRMWAREPAYLOAD,
  __module__ = 'src.third_party.chromiumos_overlay.proto.firmware_config_pb2'
  # @@protoc_insertion_point(class_scope:firmware.FirmwarePayload)
  ))
_sym_db.RegisterMessage(FirmwarePayload)

FirmwareConfig = _reflection.GeneratedProtocolMessageType('FirmwareConfig', (_message.Message,), dict(
  DESCRIPTOR = _FIRMWARECONFIG,
  __module__ = 'src.third_party.chromiumos_overlay.proto.firmware_config_pb2'
  # @@protoc_insertion_point(class_scope:firmware.FirmwareConfig)
  ))
_sym_db.RegisterMessage(FirmwareConfig)


DESCRIPTOR._options = None
# @@protoc_insertion_point(module_scope)
