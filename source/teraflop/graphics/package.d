/// Graphics pipeline primitives.
///
/// Authors: Chance Snow
/// Copyright: Copyright © 2020 Chance Snow. All rights reserved.
/// License: 3-Clause BSD License
module teraflop.graphics;

import concepts : implements;
import gfx.core.rc;
import gfx.graal;
import std.traits : fullyQualifiedName;
import std.typecons : Flag, No, Yes;

import std.conv : to;
import std.exception : enforce;
import teraflop.components : IResource, ObservableFile, ObservableFileCollection;
import teraflop.ecs : NamedComponent;
import teraflop.math;
import teraflop.traits : isStruct;

public {
  import gfx.graal : Primitive, ShaderStage;

  static import gfx.graal.pipeline;
  alias Pipeline = gfx.graal.pipeline.Pipeline;
}

/// RGBA double precision color.
struct Color {
  import core.exception : RangeError;

  /// Red component.
  double r;
  /// Blue component.
  double g;
  /// Green component.
  double b;
  /// Alpha component.
  double a;

  /// Opaque red.
  static const red = Color(1.0, 0, 0, 1.0);
  /// Opaque green.
  static const green = Color(0, 1.0, 0, 1.0);
  /// Opaque blue.
  static const blue = Color(0, 0, 1.0, 1.0);
  /// Opaque black.
  static const black = Color(0, 0, 0, 1.0);
  /// Opaque white.
  static const white = Color(1.0, 1.0, 1.0, 1.0);
  /// Fully transparent black.
  static const transparent = Color(0, 0, 0, 0);

  /// Instantiate a `Color` given double components in the range `0.0` through `1.0`.
  /// Throws: A `RangeError` if any of the given color components are outside the range `0.0` through `1.0`.
  this(double r, double g, double b, double a = 1.0) {
    const outOfBounds =
      !(r >= 0 && r <= 1.0) || !(g >= 0 && g <= 1.0) || !(b >= 0 && b <= 1.0) || !(a >= 0 && a <= 1.0);
    if (outOfBounds) throw new RangeError();
    this.r = r;
    this.g = g;
    this.b = b;
    this.a = a;
  }

  /// Instantiate a `Color` given whole integer components in the range `0` through `255`.
  /// Throws: A `RangeError` if any of the given color components are outside the range `0` through `255`.
  this(int r, int g, int b, int a = 255) {
    const outOfBounds =
      !(r >= 0 && r <= 255) || !(g >= 0 && g <= 255) || !(b >= 0 && b <= 255) || !(a >= 0 && a <= 255);
    if (outOfBounds) throw new RangeError();
    this.r = r / 255.0;
    this.g = g / 255.0;
    this.b = b / 255.0;
    this.a = a / 255.0;
  }

  /// Instantiate a `Color` given HSV components.
  /// Params:
  /// hue = Hue angle, in degrees, in the range `0` through `360`.
  /// saturation = Saturation percentage in the range `0.0` through `1.0`.
  /// value = Value percentage in the range `0.0` through `1.0`.
  /// Throws: A `RangeError` if any of the given color components are outside their respective ranges.
  static Color fromHsv(int hue, float saturation, float value) {
    import core.stdc.math : fmodf;

    // https://github.com/raysan5/raylib/blob/d7b4b9e4857809c249b0451edff8a7b93e4a3872/src/textures.c#L3535-L3563
    auto color = Color(0, 0, 0, 255);

    // Red channel
    float k = fmodf(5.0f + hue / 60.0f, 6);
    float t = 4.0f - k;
    k = (t < k)? t : k;
    k = (k < 1)? k : 1;
    k = (k > 0)? k : 0;
    color.r = value - value * saturation * k;

    // Green channel
    k = fmodf(3.0f + hue / 60.0f, 6);
    t = 4.0f - k;
    k = (t < k)? t : k;
    k = (k < 1)? k : 1;
    k = (k > 0)? k : 0;
    color.g = value - value * saturation * k;

    // Blue channel
    k = fmodf(1.0f + hue / 60.0f, 6);
    t = 4.0f - k;
    k = (t < k)? t : k;
    k = (k < 1)? k : 1;
    k = (k > 0)? k : 0;
    color.b = value - value * saturation * k;

    return color;
  }

  teraflop.math.vec3f vec3f() @property const {
    return teraflop.math.vec3f(r, g, b);
  }
  teraflop.math.vec3d vec3d() @property const {
    return teraflop.math.vec3d(r, g, b);
  }
  teraflop.math.vec4f vec4f() @property const {
    return teraflop.math.vec4f(r, g, b, a);
  }
  teraflop.math.vec4d vec4d() @property const {
    return teraflop.math.vec4d(r, g, b, a);
  }

  package (teraflop) auto toVulkan() const {
    return ClearColorValues(r.to!float, g.to!float, b.to!float, a.to!float);
  }

  /// Adjust a `Color`s alpha channel, setting it to the given percentage.
  /// Returns: A newly adjusted `Color`.
  /// Throws: A `RangeError` if the given `alpha` component is outside the range `0.0` through `1.0`.
  Color withAlpha(float alpha) const {
    const outOfBounds = alpha < 0.0 || alpha > 1.0;
    assert(!outOfBounds);
    if (outOfBounds) throw new RangeError();
    return Color(r, g, b, alpha);
  }
}

unittest {
  import std.conv : to;
  import std.math : round;

  const green = Color(0, 1.0, 0, 1.0);
  assert(green.vec3f == vec3f(0, 1, 0));
  assert(green.vec3d == vec3d(0, 1, 0));
  assert(green.vec4f == vec4f(0, 1, 0, 1));
  assert(green.vec4d == vec4d(0, 1, 0, 1));
  assert(green.withAlpha(0.5).vec4f == vec4f(0, 1, 0, 0.5));

  const cyan = Color(0, 255, 255);
  assert(cyan.vec3f == vec3f(0, 1, 1));
  assert(cyan.vec3d == vec3d(0, 1, 1));
  assert(cyan.vec4f == vec4f(0, 1, 1, 1));
  assert(cyan.vec4d == vec4d(0, 1, 1, 1));

  const muddyGreen = Color.fromHsv(139, 0.27, 0.73);
  assert(round(muddyGreen.r * 255).to!int == 136);
  assert(round(muddyGreen.g * 255).to!int == 186);
  assert(round(muddyGreen.b * 255).to!int == 152);
}

/// Detect whether `T` is vertex attribute data.
template isVertexData(T) if (isStruct!T) {
  // import std.algorithm.searching : all;
  // static immutable attributes = [__traits(allMembers, T)];
}

// TODO: Construct vertex attribute data with a template, e.g. `VertexData!(vec3f, "position", vec3f, "color")`

/// Vertex attribute data comprising a 3D position and opaque color.
struct VertexPosColor {
  /// 3D position.
  vec3f position;
  /// Opaque diffuse color.
  vec3f color;

  /// Describes how vertex attributes should be bound to the vertex shader.
  static VertexInputBinding bindingDescription() {
    VertexInputBinding bindingDescription = {
      binding: 0,
      stride: VertexPosColor.sizeof,
    };
    return bindingDescription;
  }

  /// Describes the format of each vertex attribute so that they can be applied to the vertex shader.
  static VertexInputAttrib[2] attributeDescriptions() {
    VertexInputAttrib[2] attributeDescriptions;
    // Position
    attributeDescriptions[0].binding = 0;
    attributeDescriptions[0].location = 0;
    attributeDescriptions[0].format = Format.rgb32_sFloat;
    attributeDescriptions[0].offset = position.offsetof;
    // Color
    attributeDescriptions[1].binding = 0;
    attributeDescriptions[1].location = 1;
    attributeDescriptions[1].format = Format.rgb32_sFloat;
    attributeDescriptions[1].offset = color.offsetof;
    return attributeDescriptions;
  }
}

/// Vertex attribute data comprising a 3D position, normal vector, and opaque diffuse color.
struct VertexPosNormalColor {
  /// 3D position.
  vec3f position;
  /// Normal vector.
  vec3f normal;
  /// Opaque diffuse color.
  vec3f color;

  /// Describes how vertex attributes should be bound to the vertex shader.
  static VertexInputBinding bindingDescription() {
    VertexInputBinding bindingDescription = {
      binding: 0,
      stride: VertexPosNormalColor.sizeof,
    };
    return bindingDescription;
  }

  /// Describes the format of each vertex attribute so that they can be applied to the vertex shader.
  static VertexInputAttrib[3] attributeDescriptions() {
    VertexInputAttrib[3] attributeDescriptions;
    // Position
    attributeDescriptions[0].binding = 0;
    attributeDescriptions[0].location = 0;
    attributeDescriptions[0].format = Format.rgb32_sFloat;
    attributeDescriptions[0].offset = position.offsetof;
    // Normal
    attributeDescriptions[1].binding = 0;
    attributeDescriptions[1].location = 1;
    attributeDescriptions[1].format = Format.rgb32_sFloat;
    attributeDescriptions[1].offset = normal.offsetof;
    // Color
    attributeDescriptions[2].binding = 0;
    attributeDescriptions[2].location = 2;
    attributeDescriptions[2].format = Format.rgb32_sFloat;
    attributeDescriptions[2].offset = color.offsetof;
    return attributeDescriptions;
  }
}

/// Vertex attribute data comprising a 3D position, opaque diffuse color, and texture coordinates.
struct VertexPosColorTex {
  /// 3D position.
  vec3f position;
  /// Opaque diffuse color.
  vec3f color;
  /// Texture UV coordinates.
  vec2f uv;

  /// Describes how vertex attributes should be bound to the vertex shader.
  static VertexInputBinding bindingDescription() {
    VertexInputBinding bindingDescription = {
      binding: 0,
      stride: VertexPosColorTex.sizeof,
    };
    return bindingDescription;
  }

  /// Describes the format of each vertex attribute so that they can be applied to the vertex shader.
  static VertexInputAttrib[3] attributeDescriptions() {
    VertexInputAttrib[3] attributeDescriptions;
    // Position
    attributeDescriptions[0].binding = 0;
    attributeDescriptions[0].location = 0;
    attributeDescriptions[0].format = Format.rgb32_sFloat;
    attributeDescriptions[0].offset = position.offsetof;
    // Color
    attributeDescriptions[1].binding = 0;
    attributeDescriptions[1].location = 1;
    attributeDescriptions[1].format = Format.rgb32_sFloat;
    attributeDescriptions[1].offset = color.offsetof;
    // Texture UV Coordinates
    attributeDescriptions[2].binding = 0;
    attributeDescriptions[2].location = 2;
    attributeDescriptions[2].format = Format.rg32_sFloat;
    attributeDescriptions[2].offset = uv.offsetof;
    return attributeDescriptions;
  }
}

/// Vertex attribute data comprising a 3D position, tint color, and texture coordinates.
struct VertexPosTintTex {
  /// 3D position.
  vec3f position;
  /// Tint color.
  vec4f tint;
  /// Texture UV coordinates.
  vec2f uv;

  /// Describes how vertex attributes should be bound to the vertex shader.
  static VertexInputBinding bindingDescription() {
    VertexInputBinding bindingDescription = {
      binding: 0,
      stride: VertexPosTintTex.sizeof,
    };
    return bindingDescription;
  }

  /// Describes the format of each vertex attribute so that they can be applied to the vertex shader.
  static VertexInputAttrib[3] attributeDescriptions() {
    VertexInputAttrib[3] attributeDescriptions;
    // Position
    attributeDescriptions[0].binding = 0;
    attributeDescriptions[0].location = 0;
    attributeDescriptions[0].format = Format.rgb32_sFloat;
    attributeDescriptions[0].offset = position.offsetof;
    // Color
    attributeDescriptions[1].binding = 0;
    attributeDescriptions[1].location = 1;
    attributeDescriptions[1].format = Format.rgba32_sFloat;
    attributeDescriptions[1].offset = tint.offsetof;
    // Texture UV Coordinates
    attributeDescriptions[2].binding = 0;
    attributeDescriptions[2].location = 2;
    attributeDescriptions[2].format = Format.rg32_sFloat;
    attributeDescriptions[2].offset = uv.offsetof;
    return attributeDescriptions;
  }
}

package (teraflop) abstract class MeshBase : NamedComponent, IResource {
  private Buffer _vertexBuffer;
  private Buffer _indexBuffer;
  private uint[] indices_;
  private auto dirty_ = true;

  ///
  Primitive topology = Primitive.triangleStrip;

  this(string name, Primitive topology = Primitive.triangleStrip) {
    super(name);
    this.topology = topology;
  }
  ~this() {
    if (_vertexBuffer !is null) {
      _vertexBuffer.dispose();
      destroy(_vertexBuffer);
    }
    if (_indexBuffer !is null) {
      _indexBuffer.dispose();
      destroy(_indexBuffer);
    }
  }

  /// Whether this mesh's vertex data is new or changed and needs to be uploaded to the GPU.
  bool dirty() @property const {
    return dirty_;
  }
  package (teraflop) void dirty(bool value) @property {
    dirty_ = value;
  }

  package (teraflop) Buffer vertexBuffer() @property const {
    return cast(Buffer) _vertexBuffer;
  }
  package (teraflop) Buffer indexBuffer() @property const {
    return cast(Buffer) _indexBuffer;
  }

  abstract ulong vertexCount() @property const;
  abstract size_t size() @property const;
  abstract const(ubyte[]) data() @property const;

  /// This mesh's vertex index data.
  const(uint[]) indices() @property const {
    return indices_;
  }
  protected void indices(uint[] value) @property {
    indices_ = value;
  }

  /// Describes how this mesh's vertex attributes should be bound to the vertex shader.
  abstract VertexInputBinding bindingDescription() @property const;
  /// Describes the format of this mesh's vertex attributes so that they can be applied to the vertex shader.
  abstract VertexInputAttrib[] attributeDescriptions() @property const;

  /// Whether this Mesh has been successfully initialized.
  bool initialized() @property const {
    return vertexBuffer !is null && indexBuffer !is null;
  }

  /// Initialize this Mesh.
  void initialize(scope Device device) {
    import std.algorithm.mutation : copy;
    import teraflop.platform.vulkan : createDynamicBuffer;

    assert(!initialized);

    _vertexBuffer = device.createDynamicBuffer(size, BufferUsage.vertex);
    auto vertexBuf = vertexBuffer.boundMemory.map.view!(ubyte[])[];
    assert(data.copy(vertexBuf).length == vertexBuf.length - size);

    _indexBuffer = device.createDynamicBuffer(uint.sizeof * indices.length, BufferUsage.index);
    auto indexBuf = indexBuffer.boundMemory.map.view!(uint[])[];
    assert(indices.copy(indexBuf).length == indexBuf.length - indices.length);
  }
}

/// A renderable mesh encapsulating vertex data.
class Mesh(T) : MeshBase if (isStruct!T) {
  // TODO: Make type contraint more robust, e.g. NO pointers/reference types in vertex data
  private T[] vertices_;

  /// Initialize a new mesh.
  /// Params:
  /// vertices = Mesh vertex data to optionally pre-populate.
  /// indices = Mesh vertex indices to optionally pre-populate.
  this(T[] vertices = [], uint[] indices = []) {
    this(fullyQualifiedName!(Mesh!T), vertices, indices);
  }
  /// Initialize a new mesh.
  /// Params:
  /// topology =
  /// vertices = Mesh vertex data to optionally pre-populate.
  /// indices = Mesh vertex indices to optionally pre-populate.
  this(Primitive topology = Primitive.triangleStrip, T[] vertices = [], uint[] indices = []) {
    this(fullyQualifiedName!(Mesh!T), topology, vertices, indices);
  }
  /// Initialize a new named mesh.
  /// Params:
  /// name = The name of this mesh.
  /// vertices = Mesh vertex data to optionally pre-populate.
  /// indices = Mesh vertex indices to optionally pre-populate.
  this(string name, T[] vertices = [], uint[] indices = []) {
    this(name, Primitive.triangleStrip, vertices, indices);
  }
  /// Initialize a new named mesh.
  /// Params:
  /// name = The name of this mesh.
  /// topology =
  /// vertices = Mesh vertex data to optionally pre-populate.
  /// indices = Mesh vertex indices to optionally pre-populate.
  this(string name, Primitive topology = Primitive.triangleStrip, T[] vertices = [], uint[] indices = []) {
    super(name);
    this.topology = topology;
    this.vertices_ = vertices;
    this.indices = indices;
  }

  /// This mesh's vertex data.
  const(T[]) vertices() @property const {
    return vertices_;
  }
  override ulong vertexCount() @property const {
    return vertices_.length;
  }

  /// Size of this mesh, in bytes.
  override size_t size() @property const {
    return T.sizeof * vertices_.length;
  }

  override const(ubyte[]) data() @property const {
    // https://dlang.org/spec/arrays.html#void_arrays
    const(void[]) vertexData = vertices_;
    assert(vertexData.length == size);
    return cast(ubyte[]) vertexData;
  }

  /// Describes how this mesh's vertex attributes should be bound to the vertex shader.
  override VertexInputBinding bindingDescription() @property const {
    return __traits(getMember, T, "bindingDescription");
  }
  /// Describes the format of this mesh's vertex attributes so that they can be applied to the vertex shader.
  override VertexInputAttrib[] attributeDescriptions() @property const {
    return __traits(getMember, T, "attributeDescriptions").dup;
  }

  /// Update this mesh's vertex data.
  void update(T[] vertices) {
    this.vertices_ = vertices;
    this.dirty = true;
  }
}

/// A world-space model view projection matrix. Suitable for use as a uniform buffer object.
/// See_Also: <a href="https://dlang.org/spec/attribute.html#align" title="D Language reference">`align` Attribute</a>
struct ModelViewProjection {
  /// The world-space model view projection matrix.
  mat4f mvp;
}

/// A GPU descriptor binding, e.g. uniform buffer or texture sampler.
/// See_Also:
/// $(UL
///   $(LI `teraflop.graphics.UniformBuffer`)
///   $(LI `teraflop.ecs.NamedComponent`)
/// )
abstract class BindingDescriptor : NamedComponent {
  import teraflop.async : Event;

  /// Fired when this BindingDescriptor's `data` changes.
  /// See_Also: `BindingDescriptor.dirty`
  Event!(const(ubyte)[]) onChanged;

  protected uint _bindingLocation;
  protected ShaderStage shaderStage_;
  protected DescriptorType bindingType_;
  private auto dirty_ = true;

  ///
  this(uint bindingLocation = 0) {
    super(this.classinfo.name);
    this._bindingLocation = bindingLocation;
  }
  ///
  this(string name, uint bindingLocation = 0) {
    super(name);
    this._bindingLocation = bindingLocation;
  }

  /// Whether this uniform's data is new or changed and needs to be uploaded to the GPU.
  bool dirty() @property const {
    return dirty_;
  }
  package (teraflop) void dirty(bool value) @property const {
    auto self = (cast(BindingDescriptor) this);
    self.dirty_ = value;
    if (value) self.onChanged(data);
  }

  /// Descriptor binding location, e.g. `layout(binding = 0)` in GLSL.
  uint bindingLocation() @property const {
    return _bindingLocation;
  }

  /// Which shader stages this descriptor is going to be referenced.
  ShaderStage shaderStage() @property const {
    return shaderStage_;
  }

  DescriptorType bindingType() @property const {
    return bindingType_;
  }

  package (teraflop) static auto findBinding =
    (const BindingDescriptor binding, TypeInfo_Class type) => binding.classinfo.isBaseOf(type);

  package (teraflop) WriteDescriptorSet descriptorWrite(
    DescriptorSet set, uint bindingLocation, Buffer uniformBuffer, size_t bufferOffset = 0, size_t uniformSize = 0
  ) const {
    WriteDescriptorSet descriptorSet = {
      dstSet: set,
      dstBinding: bindingLocation,
      dstArrayElem: 0,
    };
    switch (bindingType_) {
      case DescriptorType.uniformBuffer:
        assert(uniformBuffer !is null);
        if (uniformSize == 0) uniformSize = uniformBuffer.size;
        descriptorSet.write = DescriptorWrite.make(
          bindingType_, BufferDescriptor(uniformBuffer, bufferOffset, uniformSize)
        );
        break;
      case DescriptorType.sampler:
      case DescriptorType.sampledImage:
        assert(sampler !is null);
        descriptorSet.write = DescriptorWrite.make(
          bindingType_,
          ImageSamplerDescriptor(
            image !is null ? image.createView(image.info.type, ImageSubresourceRange(), Swizzle.identity) : null,
            ImageLayout.shaderReadOnlyOptimal,
            sampler,
          )
        );
        break;
      default: assert(0, "Descriptor type not supported");
    }
    return cast(WriteDescriptorSet) descriptorSet;
  }

  size_t size() @property const {
    return 0;
  }
  const(ubyte[]) data() @property const {
    return [];
  }
  package (teraflop) Sampler sampler() @property inout {
    return null;
  }
  package (teraflop) Image image() @property inout {
    return null;
  }
}

package (teraflop) struct BindingGroup {
  uint index;
  const BindingDescriptor[] bindings;
}

/// A uniform buffer object.
class UniformBuffer(T) : BindingDescriptor if (isStruct!T) {
  private T _value;

  /// Initialize a new uniform buffer.
  /// Params:
  /// bindingLocation = Uniform binding location, e.g. `layout(binding = 0)` in GLSL.
  /// shaderStage = Which shader stages the UBO is going to be referenced.
  /// value = Uniform data to optionally pre-populate.
  this(uint bindingLocation = 0, ShaderStage shaderStage = ShaderStage.allGraphics, T value = T.init) {
    super(bindingLocation);
    this.shaderStage_ = shaderStage;
    this.bindingType_ = DescriptorType.uniformBuffer;
    this._value = value;
  }
  /// Initialize a new named uniform buffer.
  /// Params:
  /// name =
  /// bindingLocation = Uniform binding location, e.g. `layout(binding = 0)` in GLSL.
  /// shaderStage = Which shader stages the UBO is going to be referenced.
  /// value = Uniform data to optionally pre-populate.
  this(string name, uint bindingLocation = 0, ShaderStage shaderStage = ShaderStage.allGraphics, T value = T.init) {
    super(name, bindingLocation);
    this.shaderStage_ = shaderStage;
    this.bindingType_ = DescriptorType.uniformBuffer;
    this._value = value;
  }

  T value() @property const {
    return _value;
  }
  void value(T value) @property {
    update(value);
  }

  override size_t size() @property const {
    return T.sizeof;
  }
  override const(ubyte[]) data() @property const {
    // https://dlang.org/spec/arrays.html#void_arrays
    const(void[]) uniformData = [value];
    assert(uniformData.length == size);
    return cast(ubyte[]) uniformData;
  }

  /// Update the uniform value.
  void update(T value) {
    this._value = value;
    this.dirty = true;
  }
}

/// A 3D camera encapsulating model, view, and projection matrices that may be bound to a vertex shader.
///
/// A World's primary camera is the `Camera` world Resource.
/// Ancillary cameras may be added to render target Entities.
class Camera : NamedComponent {
  package (teraflop) UniformBuffer!mat4f uniform;
  private mat4f model_ = mat4f.identity;
  private mat4f view_ = mat4f.identity;
  private mat4f projection_ = mat4f.identity;

  /// Whether the Y axis of the `projection` matrix shall be inverted.
  bool invertY = true;

  /// Initialize a new camera.
  /// Params:
  /// bindingLocation = Vertex shader uniform binding location, e.g. `layout(binding = 0)` in GLSL.
  this(uint bindingLocation = 0) {
    super(this.classinfo.name);
    uniform = new UniformBuffer!mat4f(bindingLocation, ShaderStage.vertex, mvp);
  }

  /// World-space model transformation matrix.
  mat4f model() @property const {
    return model_;
  }
  void model(mat4f value) @property {
    model_ = value;
    uniform.update(mvp);
  }
  /// View matrix.
  mat4f view() @property const {
    return view_;
  }
  void view(mat4f value) @property {
    view_ = value;
    uniform.update(mvp);
  }
  /// Projection matrix, e.g. orthographic or perspective.
  mat4f projection() @property const {
    return projection_;
  }
  void projection(mat4f value) @property {
    projection_ = value;
    uniform.update(mvp);
  }

  /// A combined model-view-projection matrix.
  ///
  /// The result is corrected for the Vulkan coordinate system.
  /// Vulkan clip space has inverted Y and half Z.
  /// See_Also: `vulkanClipCorrection`
  mat4f mvp() @property const {
    const clip = vulkanClipCorrection(invertY ? Yes.invertY : No.invertY);
    return (clip * projection * view * model).transposed;
  }

  ///
  ray3f mouseRay(float fovInRadians, vec3f cameraTarget, Size framebufferSize, vec2d mousePosition) const {
    // https://github.com/raysan5/raylib/blob/96db787657313c671ff618c23ffc91638cbc72b0/src/core.c#L1997

    // Calculate normalized device coordinates
    // NOTE: y value is negative
    const float x = (2.0f * mousePosition.x) / framebufferSize.width - 1.0f;
    const float y = 1.0f - (2.0f * mousePosition.y) / framebufferSize.height;
    const float z = 1.0f;

    // Store values in a vector
    auto deviceCoords = vec3f(x, y, z);

    // Calculate view matrix from camera look at
    auto view = mat4f.lookAt(view.translationOf, cameraTarget, up);
    auto proj = mat4f.identity;

    // if (camera.type == CAMERA_PERSPECTIVE) {
      // Calculate projection matrix from perspective
      proj = mat4f.perspective(fovInRadians, (framebufferSize.width / framebufferSize.height), 0.01f, 1000.0f);
    // }
    // TODO: Support orthographic cameras?
    // else if (camera.type == CAMERA_ORTHOGRAPHIC) {
    //     float aspect = (float)CORE.Window.screen.width/(float)CORE.Window.screen.height;
    //     double top = camera.fovy/2.0;
    //     double right = top*aspect;

    //     // Calculate projection matrix from orthographic
    //     proj = MatrixOrtho(-right, right, -top, top, 0.01, 1000.0);
    // }

    // Unproject far/near points
    const nearPoint = vec3f(deviceCoords.x, deviceCoords.y, 0.0f).unproject(view * proj);
    const farPoint = vec3f(deviceCoords.x, deviceCoords.y, 1.0f).unproject(view * proj);

    // Unproject the mouse cursor in the near plane.
    // We need this as the source position because orthographic projects, compared to perspect doesn't have a
    // convergence point, meaning that the "eye" of the camera is more like a plane than a point.
    // auto cameraPlanePointerPos = vec3f(deviceCoords.x, deviceCoords.y, -1.0f).unproject(view * proj);

    // Calculate normalized direction vector
    auto direction = (farPoint - nearPoint).normalized;

    // if (camera.type == CAMERA_PERSPECTIVE) ray.orig = view.translationOf;
    // else if (camera.type == CAMERA_ORTHOGRAPHIC) ray.orig = cameraPlanePointerPos;

    return ray3f(view.translationOf, direction);
  }
}

/// A 2D image stored in GPU memory.
class Texture : BindingDescriptor, IResource {
  import gfx.graal : Image, Sampler;

  private Device device;
  private Size _size;

  /// Data format of a Texture's `data`.
  static const format = Format.bgra8_sRgb;
  /// Manner in which this Texture will be used. Defaults to `ImageUsage.sampled | ImageUsage.transferDst`.
  /// See_Also: `defaultUsage`
  const ImageUsage usage;
  /// Default value of a Texture's `usage`.
  /// See_Also: `usage`
  static const defaultUsage = ImageUsage.sampled | ImageUsage.transferDst;

  private ubyte[] _data;
  private Buffer stagingBuffer;
  private Image _image;
  private Sampler _sampler;

  /// Initialize a new Texture.
  this(const Size size, ImageUsage usage = defaultUsage, ShaderStage shaderStage = ShaderStage.fragment) {
    this(size, 0, usage, shaderStage);
  }
  /// Initialize a new named Texture.
  this(string name, const Size size, ImageUsage usage = defaultUsage, ShaderStage shaderStage = ShaderStage.fragment) {
    this(name, size, 0, usage, shaderStage);
  }
  /// Initialize a new Texture.
  this(
    const Size size, uint bindingLocation, ImageUsage usage = defaultUsage,
    ShaderStage shaderStage = ShaderStage.fragment
  ) {
    super(bindingLocation);
    bindingType_ = DescriptorType.sampledImage;
    shaderStage_ = shaderStage;

    this._size = size;
    assert(
      (usage & ImageUsage.transferDst) == ImageUsage.transferDst,
      "Must include `ImageUsage.transferDst`.\n\tAll Textures make use of a staging buffer."
    );
    this.usage = usage;
  }
  /// Initialize a new named Texture.
  this(
    string name, const Size size, uint bindingLocation, ImageUsage usage = defaultUsage,
    ShaderStage shaderStage = ShaderStage.fragment
  ) {
    super(name, bindingLocation);
    bindingType_ = DescriptorType.sampledImage;
    shaderStage_ = shaderStage;

    this._size = size;
    assert(
      (usage & ImageUsage.transferDst) == ImageUsage.transferDst,
      "Must include `ImageUsage.transferDst`.\n\tAll Textures make use of a staging buffer."
    );
    this.usage = usage;
  }
  /// Initialize a new Texture with initial data.
  this(
    const Size size, ubyte[] data, uint bindingLocation = 0, ImageUsage usage = defaultUsage,
    ShaderStage shaderStage = ShaderStage.fragment
  ) {
    this(size, bindingLocation, usage, shaderStage);
    this._data = data;
    dirty = true;
  }
  /// Initialize a new named Texture with initial data.
  this(
    string name, const Size size, ubyte[] data, uint bindingLocation = 0, ImageUsage usage = defaultUsage,
    ShaderStage shaderStage = ShaderStage.fragment
  ) {
    this(name, size, bindingLocation, usage, shaderStage);
    this._data = data;
    dirty = true;
  }
  ~this() {
    if (stagingBuffer !is null) {
      stagingBuffer.dispose();
      stagingBuffer = null;
    }
    if (_image !is null) {
      _image.dispose();
      _image = null;
    }
    if (_sampler !is null) {
      _sampler.dispose();
      _sampler = null;
    }
  }

  ///
  override size_t size() @property const {
    return _size.width * _size.height * 4;
  }

  /// Size of this Texture, in pixels.
  Size dimensions() @property const {
    return _size;
  }

  /// Whether this Shader has been successfully initialized.
  bool initialized() @property const {
    return stagingBuffer !is null &&
      (cast(Buffer) stagingBuffer).size == size &&
      _image !is null && _sampler !is null;
  }

  /// Texture data.
  override const(ubyte[]) data() @property const {
    return _data;
  }

  package (teraflop) Buffer buffer() @property const {
    return cast(Buffer) stagingBuffer;
  }
  package (teraflop) Sampler sampler() @property inout {
    return cast(Sampler) _sampler;
  }
  package (teraflop) Image image() @property inout {
    return cast(Image) _image;
  }

  /// Initialize this Texture.
  void initialize(scope Device device) {
    import teraflop.platform.vulkan : createDynamicBuffer, createImage;

    assert(!initialized);

    this.device = device;
    stagingBuffer = device.createDynamicBuffer(size, BufferUsage.transferSrc);
    _image = createImage(device, dimensions, format, usage);
    _sampler = device.createSampler(SamplerInfo.nearest.withWrapMode(WrapMode.border));

    if (this._data.length) copyToStage();
  }

  /// Resize this Texture.
  void resize(const Size size) {
    import std.algorithm : joiner, map;
    import std.array : array;
    import std.math : round;
    import std.range : repeat;

    this._data = [];
    this._size = size;
    if (stagingBuffer !is null) {
      device.waitIdle();
      stagingBuffer.dispose();
      stagingBuffer = null;
    }
    if (_image !is null) {
      device.waitIdle();
      _image.dispose();
      _image = null;
    }
    if (_sampler !is null) {
      device.waitIdle();
      _sampler.dispose();
      _sampler = null;
    }
    // Fill the texture with transparent pixels
    update(Color.transparent.repeat(size.width * size.height).map!(pixel => [
      round(pixel.b * 255.0f).to!ubyte,
      round(pixel.g * 255.0f).to!ubyte,
      round(pixel.r * 255.0f).to!ubyte,
      round(pixel.a * 255.0f).to!ubyte
    ]).joiner.array);
  }

  /// Update this Texture's data.
  void update(ubyte[] data) {
    this._data = data;
    dirty = true;
    if (stagingBuffer !is null && _data.length == stagingBuffer.size)
      copyToStage();
  }

  private void copyToStage() {
    import std.algorithm.mutation : copy;

    assert(stagingBuffer !is null);
    auto buf = stagingBuffer.boundMemory.map.view!(ubyte[])[];
    const unfilled = data.copy(buf);
    assert(unfilled.length == 0);
  }
}

/// A SPIR-V program for one programmable stage in the graphics `Pipeline`.
/// See_Also: `ObservableFile`
class Shader : ObservableFile, IResource {
  /// The stage in the graphics pipeline in which this Shader performs.
  const ShaderStage stage;

  private Device device;
  private ShaderModule _shaderModule;

  /// Initialize a new Shader compiled from the given `filePath`.
  ///
  /// Params:
  /// stage = The stage in the graphics pipeline in which this Shader performs.
  /// filePath = Path to a file containing SPIR-V source bytecode.
  /// hotReload = Whether to watch the given `filePath` for changes and to recompile this Shader at runtime.
  this(ShaderStage stage, string filePath, Flag!"hotReload" hotReload = No.hotReload) {
    import std.string : format;

    this.stage = stage;
    super(filePath, hotReload);
    enforce(exists, format!"File not found: %s"(filePath));
    onChanged ~= (const(ubyte)[] _) => {
      if (_shaderModule !is null) {
        // TODO: Log "Reloading shader: filePath"
        device.waitIdle();
        _shaderModule.dispose();
        _shaderModule = null;
      }
    }();
  }
  /// Initialize a new Shader.
  ///
  /// Params:
  /// stage = The stage in the graphics pipeline in which this Shader performs.
  /// spv = SPIR-V source bytecode.
  this(ShaderStage stage, ubyte[] spv) {
    this.stage = stage;
    super(spv);
  }
  ~this() {
    if (_shaderModule !is null) _shaderModule.dispose();
  }

  /// Initialize a new Shader compiled from the given `filePath`.
  /// The constructed Shader will be marked for `hotReload`.
  ///
  /// Add the `teraflop.systems.FileWatcher` System to your game's World to watch the Shader's source file for changes.
  ///
  /// Params:
  /// stage = The stage in the graphics pipeline in which this Shader performs.
  /// filePath = Path to a file containing SPIR-V source bytecode.
  /// See_Also: `teraflop.systems.FileWatcher`
  static Shader watched(ShaderStage stage, string filePath) {
    return new Shader(stage, filePath, Yes.hotReload);
  }

  /// Whether this Shader has been successfully initialized.
  bool initialized() @property const {
    return _shaderModule !is null;
  }

  ShaderModule shaderModule() @property const {
    return cast(ShaderModule) _shaderModule;
  }

  /// Initialize this Shader.
  void initialize(scope Device device) {
    assert(!initialized);
    this.device = device;
    this._shaderModule = device.createShaderModule(cast(uint[]) contents, "main");
  }
}

/// Type of <a href="https://en.wikipedia.org/wiki/Back-face_culling">face culling</a> to use during graphic pipeline rasterization.
enum CullMode : Cull {
  /// Disable face culling.
  none = Cull.none,
  /// Cull front faces.
  front = Cull.front,
  /// Cull back faces.
  back = Cull.back,
  /// Cull both front and back faces.
  both = Cull.frontAndBack
}

/// Specifies the vertex order for faces to be considered front-facing.
enum FrontFace : gfx.graal.FrontFace {
  /// Clockwise ordered faces will be considered front-facing.
  clockwise = gfx.graal.FrontFace.cw,
  /// Counter-clockwise ordered faces will be considered front-facing.
  counterClockwise = gfx.graal.FrontFace.ccw
}

/// Argument to the `Material.onDirtied` `Event`.
/// See_Also: `Material.dirtied`
struct MaterialDirtied {
  package Material material;
  package(teraflop) size_t formerMaterialHash;

  /// The `Shader` that changed.
  /// See_Also: `Material.shaders`
  Shader shader;
  /// The `Texture` that changed.
  /// See_Also: `Material.textured`
  Texture texture;

  /// Whether a `Material` was dirtied because one of its `Shader` changed.
  /// See_Also: $UL(
  ///   $(LI `Material.shaders`)
  ///   $(LI `Material.dirtied`)
  /// )
  bool shaderChanged() @property const {
    return shader !is null;
  }

  /// Whether a textured `Material` was dirtied because its `Texture` changed.
  /// See_Also: $UL(
  ///   $(LI `Material.textured`)
  ///   $(LI `Material.dirtied`)
  /// )
  bool textureChanged() @property const {
    return texture !is null;
  }

  package (teraflop) void resetDirtied() @property const {
    (cast(MaterialDirtied) this).material.resetDirtied();
  }
}

/// A shaded material for geometry encapsulating its `Shader`s, graphics pipeline state, and optionally a `Texture`.
/// See_Also: `teraflop.systems.rendering.PipelinePreparer`
class Material : ObservableFileCollection, IResource {
  private size_t _formerMaterialHash;
  private MaterialDirtied* _dirtied = null;

  private bool _depthTest = true;
  private FrontFace _frontFace = FrontFace.clockwise;
  private CullMode _cullMode = CullMode.back;

  package (teraflop) Shader[] _shaders;
  package (teraflop) Texture _texture;

  /// Initialize a new Material.
  this(Shader[] shaders, Flag!"depthTest" depthTest = Yes.depthTest) {
    this(fullyQualifiedName!Material, shaders, FrontFace.clockwise, CullMode.back, depthTest);
  }
  /// Initialize a new Material.
  this(
    Shader[] shaders,
    FrontFace frontFace = FrontFace.clockwise, CullMode cullMode = CullMode.back,
    Flag!"depthTest" depthTest = Yes.depthTest
  ) {
    this(fullyQualifiedName!Material, shaders, frontFace, cullMode, depthTest);
  }
  /// Initialize a new textured Material.
  this(
    Shader[] shaders, Texture texture,
    FrontFace frontFace = FrontFace.clockwise, CullMode cullMode = CullMode.back,
    Flag!"depthTest" depthTest = Yes.depthTest
  ) {
    this(fullyQualifiedName!Material, shaders, texture, frontFace, cullMode, depthTest);
  }
  /// Initialize a new named Material.
  this(
    string name, Shader[] shaders,
    FrontFace frontFace = FrontFace.clockwise, CullMode cullMode = CullMode.back,
    Flag!"depthTest" depthTest = Yes.depthTest
  ) {
    this(name, shaders, null, frontFace, cullMode, depthTest);
  }
  /// Initialize a new named and textured Material.
  this(
    string name, Shader[] shaders, Texture texture,
    FrontFace frontFace = FrontFace.clockwise, CullMode cullMode = CullMode.back,
    Flag!"depthTest" depthTest = Yes.depthTest
  ) {
    this._depthTest = depthTest;
    this._frontFace = frontFace;
    this._cullMode = cullMode;
    this._shaders = shaders;
    this._texture = texture;
    this._formerMaterialHash = this.toHash;

    super(name, shaders.to!(ObservableFile[]));
    foreach(shader; shaders) {
      shader.onChanged ~= (const(ubyte)[] _) => {
        _dirtied = new MaterialDirtied(this, _formerMaterialHash, shader);
        _formerMaterialHash = this.toHash;
      }();
    }

    if (textured) texture.onChanged ~= (const(ubyte)[] _) => {
      _dirtied = new MaterialDirtied(this, _formerMaterialHash, null, texture);
      _formerMaterialHash = this.toHash;
    }();
  }
  ~this() {
    foreach (shader; _shaders)
      destroy(shader);
    if (textured) destroy(texture);
  }

  /// Whether this Shader has been successfully initialized.
  bool initialized() @property const {
    import std.algorithm.searching : all;

    if (!_shaders.length) return true;
    return _shaders.all!(shader => shader.initialized) && (!textured || texture.initialized);
  }

  /// Whether to perform the depth test. If `true`, assumes the render target has a depth buffer attachment.
  bool depthTest() @property const {
    return _depthTest;
  }
  /// Specifies the vertex order for faces to be considered front-facing.
  FrontFace frontFace() @property const {
    return _frontFace;
  }
  /// Type of <a href="https://en.wikipedia.org/wiki/Back-face_culling">face culling</a> to use during graphic pipeline rasterization.
  CullMode cullMode() @property const {
    return _cullMode;
  }

  GraphicsShaderSet shaders() @property const {
    import std.algorithm : canFind, find;

    auto findShader = (const Shader s, ShaderStage st) => s.stage == st;

    GraphicsShaderSet shaderSet = {
      vertex: _shaders.canFind!(findShader)(ShaderStage.vertex)
        ? _shaders.find!(findShader)(ShaderStage.vertex)[0].shaderModule
        : null,
      tessControl: _shaders.canFind!(findShader)(ShaderStage.tessellationControl)
        ? _shaders.find!(findShader)(ShaderStage.tessellationControl)[0].shaderModule
        : null,
      tessEval: _shaders.canFind!(findShader)(ShaderStage.tessellationEvaluation)
        ? _shaders.find!(findShader)(ShaderStage.tessellationEvaluation)[0].shaderModule
        : null,
      geometry: _shaders.canFind!(findShader)(ShaderStage.geometry)
        ? _shaders.find!(findShader)(ShaderStage.geometry)[0].shaderModule
        : null,
      fragment: _shaders.canFind!(findShader)(ShaderStage.fragment)
        ? _shaders.find!(findShader)(ShaderStage.fragment)[0].shaderModule
        : null,
    };
    return shaderSet;
  }

  /// Whether this Material is textured.
  ///
  /// Be sure to check `Material.textured` before accessing this property.
  Texture texture() @property const {
    assert(textured, "This Material is not textured!\n\tHint: Check `Material.textured` beforehand.");
    return cast(Texture) _texture;
  }
  /// Whether this Material is textured.
  /// See_Also: `Material.texture`
  bool textured() @property const {
    return _texture !is null;
  }

  /// Whether this Material has changed and requires reprocessing into the graphics pipeline.
  /// See_Also:
  /// $(UL
  ///   $(LI `Material.dirtied`)
  ///   $(LI `teraflop.systems.rendering.PipelinePreparer`)
  /// )
  bool dirty() @property const {
    return _dirtied !is null;
  }
  package (teraflop) void resetDirtied() @property const {
    (cast(Material) this)._dirtied = null;
  }
  /// The properties of this Material that have changed.
  ///
  /// Be sure to check `Material.dirty` before accessing this property.
  /// See_Also: `Material.dirty`
  const(MaterialDirtied) dirtied() @property const {
    assert(dirty, "This Material is not dirty!\n\tHint: Check `Material.dirty` beforehand.");
    return *_dirtied;
  }

  /// Pipelines are keyed on `Material`s, `MeshBase.bindingDescription`, `MeshBase.attributeDescriptions`, and `MeshBase.topology`
  /// See_Also: <a href="https://dlang.org/spec/hash-map.html#using_classes_as_key" title="The D Language Website">Associative Arrays - Using Classes as the <em>KeyType</em></a>
  override size_t toHash() const pure {
    size_t accumulatedHash = _cullMode.hashOf(_frontFace.hashOf(_depthTest));
    foreach (shader; _shaders)
      accumulatedHash = shader.contents.hashOf(accumulatedHash);
    return accumulatedHash;
  }
  override bool opEquals(Object o) const pure {
    Material other = cast(Material) o;
    return other && toHash() == other.toHash();
  }

  /// Initialize this Material.
  override void initialize(scope Device device) {
    foreach (shader; _shaders) if (!shader.initialized) shader.initialize(device);
    if (_texture !is null && !_texture.initialized)
      texture.initialize(device);
  }
}

version (unittest) {
  import teraflop.platform.vulkan : FrameData;

  private class TestFrameData : FrameData {
    PrimaryCommandBuffer cmdBuf;
    Rc!Framebuffer frameBuffer;

    this(
      Device device, uint queueFamilyIndex, ImageBase swcColor, RenderPass renderPass, CommandBuffer tempBuf = null
    ) {
      super(device, queueFamilyIndex, swcColor);
      cmdBuf = cmdPool.allocatePrimary(1)[0];

      cmdBuf.begin(CommandBufferUsage.simultaneousUse);
      cmdBuf.end();

      frameBuffer = device.createFramebuffer(renderPass, [
        swcColor.createView(
          ImageType.d2,
          ImageSubresourceRange(ImageAspect.color),
          Swizzle.identity
        )
      ], size.width, size.height, 1);
    }

    override void dispose() {
      cmdPool.free([ cast(CommandBuffer)cmdBuf ]);
      frameBuffer.unload();
      super.dispose();
    }
  }
}

version (GPU) {
  import teraflop.platform.vulkan;
}

version (unittest) {
  version (GPU) {
    import teraflop.ecs : MockScene, System, World;
    import teraflop.systems;

    class MockTriangleScene : MockScene, SurfaceSizeProvider {

      const Size renderTargetSize;

      private Device _device;
      private Queue graphicsQueue;
      private Image _renderTarget;
      private Texture _renderTargetTexture;
      private Rc!RenderPass renderPass;
      private TestFrameData frameBuffer;
      private PipelinePreparer pipelinePreparer;
      private auto systems = new System[0];

      private MeshBase _triangle;
      private Material _material;

      this(Size renderTargetSize = Size(400, 400)) {
        import gfx.core : none;

        assert(initVulkan("test-triangle"));
        const graphicsQueueIndex = selectGraphicsQueue();
        enforce(graphicsQueueIndex >= 0, "Try upgrading your graphics drivers.");
        _device = selectGraphicsDevice(graphicsQueueIndex);
        graphicsQueue = _device.getQueue(graphicsQueueIndex, 0);

        this.renderTargetSize = renderTargetSize;
        _renderTarget = createImage(_device, renderTargetSize, Format.bgra8_sRgb, ImageUsage.colorAttachment);
        _renderTargetTexture = new Texture(Size(renderTargetSize.width / 2, renderTargetSize.width / 2));
        _renderTargetTexture.initialize(_device);

        // Setup render pass
        const attachments = [AttachmentDescription(renderTarget.info.format, 1,
          AttachmentOps(LoadOp.clear, StoreOp.store),
          AttachmentOps(LoadOp.dontCare, StoreOp.dontCare),
          trans(ImageLayout.undefined, ImageLayout.presentSrc),
          No.mayAlias
        )];
        const subpasses = [SubpassDescription(
          [], [ AttachmentRef(0, ImageLayout.colorAttachmentOptimal) ],
          none!AttachmentRef, []
        )];
        renderPass = _device.createRenderPass(attachments, subpasses, []);
        frameBuffer = new TestFrameData(_device, graphicsQueueIndex, renderTarget, renderPass);

        // Setup pipeline preparer
        pipelinePreparer = new PipelinePreparer(world, _device, renderPass.obj);

        // Setup built-in Systems
        systems ~= new ResourceInitializer(world, _device);
        systems ~= new TextureUploader(world, new OneTimeCmdBufPool(_device, graphicsQueue));
      }
      ~this() {
        import std.string : format;

        // Gracefully release GPU and other unmanaged resources
        new ResourceGarbageCollector(world, _device).run();
        foreach (system; systems) destroy(system);
        _device.waitIdle();
        destroy(world);

        destroy(pipelinePreparer);

        _device.waitIdle();
        destroy(_renderTargetTexture);
        _renderTarget.dispose();
        renderPass.unload();
        frameBuffer.dispose();

        assert(
          device.refCount == 0,
          format!"Vulkan device was not released! %d remaining handle(s)."(device.refCount)
        );
        unloadVulkan();
      }

      const(Size) surfaceSize() @property const {
        return renderTargetSize;
      }

      @property Device device() {
        return _device;
      }
      @property Image renderTarget() {
        return _renderTarget;
      }
      @property Texture renderTargetTexture() {
        return _renderTargetTexture;
      }
      @property MeshBase triangle() {
        return _triangle;
      }
      @property Material material() {
        return _material;
      }

      void initializeWorld() {
        initializeWorld(world);
      }

      protected override void initializeWorld(scope World world) {
        world.resources.add(this);

        _triangle = new Mesh!VertexPosColor([
          VertexPosColor(vec3f(0.0f, -0.5f, 0), Color.red.vec3f),
          VertexPosColor(vec3f(0.5f, 0.5f, 0), Color.green.vec3f),
          VertexPosColor(vec3f(-0.5f, 0.5f, 0), Color.blue.vec3f),
        ], [0, 1, 2]);
        _material = new Material([
          new Shader(ShaderStage.vertex, "examples/triangle/assets/shaders/triangle.vs.spv"),
          new Shader(ShaderStage.fragment, "examples/triangle/assets/shaders/triangle.fs.spv")
        ], No.depthTest);

        world.spawn(_triangle, _material);
      }

      void update() {
        import std.exception : assertNotThrown;
        import teraflop.ecs : SystemException;

        pipelinePreparer.run();

        foreach (system; systems)
          assertNotThrown!SystemException(system.run());
      }

      void renderFrame() {
        update();

        auto commands = frameBuffer.cmdPool.allocatePrimary(1)[0];
        commands.begin(CommandBufferUsage.oneTimeSubmit);
        const clearColor = Color.black.toVulkan;
        commands.beginRenderPass(
          renderPass, frameBuffer.frameBuffer,
          Rect(0, 0, renderTargetSize.width, renderTargetSize.height),
          [ClearValues(clearColor)]
        );
        foreach (renderable; pipelinePreparer.renderables) {
          commands.bindPipeline(cast(Pipeline) renderable.pipeline);
          commands.bindVertexBuffers(0, [VertexBinding(renderable.mesh.vertexBuffer, 0)]);
          commands.bindIndexBuffer(renderable.mesh.indexBuffer, 0, IndexType.u32);
          if (renderable.descriptorSet !is null) commands.bindDescriptorSets(
            PipelineBindPoint.graphics, cast(PipelineLayout) renderable.layout, 0,
            cast(DescriptorSet[]) [renderable.descriptorSet], []
          );
          foreach (i, pushConstant; renderable.pushBindings) commands.pushConstants(
            cast(PipelineLayout) renderable.layout, pushConstant.shaderStage, i,
            pushConstant.size, pushConstant.data.ptr
          );
          commands.drawIndexed(renderable.mesh.indices.length.to!uint, 1, 0, 0, 0);
        }
        commands.endRenderPass();
        commands.end();

        auto submissions = [Submission([], [], [commands])];
        graphicsQueue.submit(submissions, null);
        // Wait for frame to finish rendering
        device.waitIdle();
      }
    }
  }

  unittest {
    version (GPU) {
      import std.conv : to;

      auto scene = new MockTriangleScene();
      assert(scene.renderTargetTexture.initialized);

      // Resize render target
      scene.renderTargetTexture.resize(scene.renderTargetSize);
      assert(!scene.renderTargetTexture.initialized);

      scene.renderTargetTexture.initialize(scene.device);
      assert(scene.renderTargetTexture.initialized);

      // Render a triangle scene to a single image
      scene.initializeWorld();
      assert( scene.material.frontFace == FrontFace.clockwise);
      assert( scene.material.cullMode == CullMode.back);
      assert(!scene.material.textured);
      assert(!scene.material.dirty);
      assert(scene.triangle.dirty);
      assert(scene.triangle.vertexCount == 3);
      assert(scene.triangle.indices == [0, 1, 2]);

      scene.update();
      assert(scene.material.initialized);
      assert(scene.triangle.initialized);

      scene.renderFrame();
      // TODO: Diff with a PPM file (https://github.com/aquaratixc/ppmformats), e.g. https://github.com/mruby/mruby/blob/master/benchmark/bm_ao_render.rb#L308

      // Gracefully teardown GPU resources
      destroy(scene);
    }
  }
}
