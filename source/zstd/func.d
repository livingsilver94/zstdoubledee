module zstd.func;

import std.format;
import std.stdint;
import std.string;
import std.typecons : tuple, Tuple;

import zstd.c.symbols;
import zstd.common;

uint32_t versionNumber() @trusted
{
    return ZSTD_versionNumber();
}

unittest
{
    assert(versionNumber() > 0);
}

string versionString() @trusted
{
    return cast(string) std.string.fromStringz(ZSTD_versionString());
}

unittest
{
    assert(versionString().length > 0);
}

CompressionLevel minCompressionLevel()
{
    return ZSTD_minCLevel();
}

unittest
{
    assert(minCompressionLevel() < 0);
}

CompressionLevel defaultCompressionLevel() @trusted
{
    return ZSTD_defaultCLevel();
}

unittest
{
    const auto lvl = defaultCompressionLevel();
    assert(lvl >= minCompressionLevel && lvl <= maxCompressionLevel);
}

CompressionLevel maxCompressionLevel() @trusted
{
    return ZSTD_maxCLevel();
}

unittest
{
    assert(maxCompressionLevel() >= 22);
}

size_t compress(void[] dst, const void[] src, CompressionLevel lvl) @trusted
{
    const auto size = ZSTD_compress(cast(void*) dst, dst.length, cast(const void*) src, src.length, lvl);
    ZSTDException.raiseIfError(size);
    return size;
}

size_t decompress(void[] dst, const void[] src, size_t compressedSize) @trusted
{
    const auto size = ZSTD_decompress(cast(void*) dst, dst.length, cast(const void*) src, compressedSize);
    ZSTDException.raiseIfError(size);
    return size;
}

class FrameContentSizeException : ZSTDException
{
private:
    this(Kind kind, string filename = __FILE__, size_t line = __LINE__) @safe
    {
        super(kindToString(kind), filename, line);
    }

    enum Kind : uint64_t
    {
        SizeUnknown = -1,
        SizeError = -2,
    }

    static bool isError(uint64_t size) @safe
    {
        return size >= Kind.min && size <= Kind.max;
    }

    static string kindToString(Kind kind) @safe
    {
        final switch (kind)
        {
        case Kind.SizeUnknown:
            {
                return std.format.format("size cannot be determined (code %d)", kind);
            }
        case Kind.SizeError:
            {
                return std.format.format("one of the arguments is invalid (code %d)", kind);
            }
        }
    }
}

uint64_t getFrameContentSize(const void[] src) @trusted
{
    const auto size = ZSTD_getFrameContentSize(cast(const void*) src, src.length);
    if (FrameContentSizeException.isError(size))
    {
        throw new FrameContentSizeException(cast(FrameContentSizeException.Kind) size);
    }
    return size;
}

size_t findFrameCompressedSize(const void[] src) @trusted
{
    const auto size = ZSTD_findFrameCompressedSize(cast(const void*) src, src.length);
    ZSTDException.raiseIfError(size);
    return size;
}

size_t compressBound(size_t srcSize) @trusted
{
    return ZSTD_compressBound(srcSize);
}

uint32_t getDictIDFromDict(const void[] dict)
{
    return ZSTD_getDictID_fromDict(cast(const void*) dict, dict.length);
}

uint32_t getDictIDFromFrame(const void[] src)
{
    return ZSTD_getDictID_fromFrame(cast(const void*) src, src.length);
}

bool isSkippableFrame(const void[] buffer)
{
    return cast(bool) ZSTD_isSkippableFrame(cast(const void*) buffer, buffer.length);
}

Tuple!(size_t, uint32_t) readSkippableFrame(void[] dst, const void[] src)
{
    uint32_t magicVariant;
    auto nBytes = ZSTD_readSkippableFrame(
        cast(void*) dst,
        dst.length,
        &magicVariant,
        cast(const void*) src,
        src.length);
    ZSTDException.raiseIfError(nBytes);
    return tuple(nBytes, magicVariant);
}
