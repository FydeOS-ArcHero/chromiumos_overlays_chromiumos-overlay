# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: src/third_party/chromiumos-overlay/proto/build_target_config_id.proto

import sys
_b=sys.version_info[0]<3 and (lambda x:x) or (lambda x:x.encode('latin1'))
from google.protobuf import descriptor as _descriptor
from google.protobuf import message as _message
from google.protobuf import reflection as _reflection
from google.protobuf import symbol_database as _symbol_database
# @@protoc_insertion_point(imports)

_sym_db = _symbol_database.Default()




DESCRIPTOR = _descriptor.FileDescriptor(
  name='src/third_party/chromiumos-overlay/proto/build_target_config_id.proto',
  package='chromiumos_overlay',
  syntax='proto3',
  serialized_options=_b('ZMgo.chromium.org/chromiumos/config/go/src/third_party/chromiumos-overlay/proto'),
  serialized_pb=_b('\nEsrc/third_party/chromiumos-overlay/proto/build_target_config_id.proto\x12\x12\x63hromiumos_overlay\"$\n\x13\x42uildTargetConfigId\x12\r\n\x05value\x18\x01 \x01(\tBOZMgo.chromium.org/chromiumos/config/go/src/third_party/chromiumos-overlay/protob\x06proto3')
)




_BUILDTARGETCONFIGID = _descriptor.Descriptor(
  name='BuildTargetConfigId',
  full_name='chromiumos_overlay.BuildTargetConfigId',
  filename=None,
  file=DESCRIPTOR,
  containing_type=None,
  fields=[
    _descriptor.FieldDescriptor(
      name='value', full_name='chromiumos_overlay.BuildTargetConfigId.value', index=0,
      number=1, type=9, cpp_type=9, label=1,
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
  serialized_start=93,
  serialized_end=129,
)

DESCRIPTOR.message_types_by_name['BuildTargetConfigId'] = _BUILDTARGETCONFIGID
_sym_db.RegisterFileDescriptor(DESCRIPTOR)

BuildTargetConfigId = _reflection.GeneratedProtocolMessageType('BuildTargetConfigId', (_message.Message,), dict(
  DESCRIPTOR = _BUILDTARGETCONFIGID,
  __module__ = 'src.third_party.chromiumos_overlay.proto.build_target_config_id_pb2'
  # @@protoc_insertion_point(class_scope:chromiumos_overlay.BuildTargetConfigId)
  ))
_sym_db.RegisterMessage(BuildTargetConfigId)


DESCRIPTOR._options = None
# @@protoc_insertion_point(module_scope)
