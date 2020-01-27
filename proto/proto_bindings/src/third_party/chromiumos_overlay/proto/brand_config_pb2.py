# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: src/third_party/chromiumos-overlay/proto/brand_config.proto

import sys
_b=sys.version_info[0]<3 and (lambda x:x) or (lambda x:x.encode('latin1'))
from google.protobuf import descriptor as _descriptor
from google.protobuf import message as _message
from google.protobuf import reflection as _reflection
from google.protobuf import symbol_database as _symbol_database
# @@protoc_insertion_point(imports)

_sym_db = _symbol_database.Default()


from src.platform2.chromeos_config.proto import brand_id_scan_config_pb2 as src_dot_platform2_dot_chromeos__config_dot_proto_dot_brand__id__scan__config__pb2


DESCRIPTOR = _descriptor.FileDescriptor(
  name='src/third_party/chromiumos-overlay/proto/brand_config.proto',
  package='chromiumos_overlay',
  syntax='proto3',
  serialized_options=_b('ZMgo.chromium.org/chromiumos/config/go/src/third_party/chromiumos-overlay/proto'),
  serialized_pb=_b('\n;src/third_party/chromiumos-overlay/proto/brand_config.proto\x12\x12\x63hromiumos_overlay\x1a>src/platform2/chromeos-config/proto/brand_id_scan_config.proto\"Y\n\x0b\x42randConfig\x12\x37\n\x0bscan_config\x18\x01 \x01(\x0b\x32\".chromeos_config.BrandIdScanConfig\x12\x11\n\twallpaper\x18\x02 \x01(\tBOZMgo.chromium.org/chromiumos/config/go/src/third_party/chromiumos-overlay/protob\x06proto3')
  ,
  dependencies=[src_dot_platform2_dot_chromeos__config_dot_proto_dot_brand__id__scan__config__pb2.DESCRIPTOR,])




_BRANDCONFIG = _descriptor.Descriptor(
  name='BrandConfig',
  full_name='chromiumos_overlay.BrandConfig',
  filename=None,
  file=DESCRIPTOR,
  containing_type=None,
  fields=[
    _descriptor.FieldDescriptor(
      name='scan_config', full_name='chromiumos_overlay.BrandConfig.scan_config', index=0,
      number=1, type=11, cpp_type=10, label=1,
      has_default_value=False, default_value=None,
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      serialized_options=None, file=DESCRIPTOR),
    _descriptor.FieldDescriptor(
      name='wallpaper', full_name='chromiumos_overlay.BrandConfig.wallpaper', index=1,
      number=2, type=9, cpp_type=9, label=1,
      has_default_value=False, default_value=_b("").decode('utf-8'),
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
  serialized_start=147,
  serialized_end=236,
)

_BRANDCONFIG.fields_by_name['scan_config'].message_type = src_dot_platform2_dot_chromeos__config_dot_proto_dot_brand__id__scan__config__pb2._BRANDIDSCANCONFIG
DESCRIPTOR.message_types_by_name['BrandConfig'] = _BRANDCONFIG
_sym_db.RegisterFileDescriptor(DESCRIPTOR)

BrandConfig = _reflection.GeneratedProtocolMessageType('BrandConfig', (_message.Message,), dict(
  DESCRIPTOR = _BRANDCONFIG,
  __module__ = 'src.third_party.chromiumos_overlay.proto.brand_config_pb2'
  # @@protoc_insertion_point(class_scope:chromiumos_overlay.BrandConfig)
  ))
_sym_db.RegisterMessage(BrandConfig)


DESCRIPTOR._options = None
# @@protoc_insertion_point(module_scope)
