import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/core/shaders/fluid_shader.dart';
import 'package:jplayer/src/core/shaders/shader_config.dart';

export 'fluid_shader.dart';
export 'shader_config.dart';

ShaderConfig? studioShaderFor(StudioBackground background) =>
    switch (background) {
      StudioBackground.aurora => null,
      StudioBackground.fluid => FluidShader.config,
    };
