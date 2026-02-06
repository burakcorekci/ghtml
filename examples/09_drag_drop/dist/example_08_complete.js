// build/dev/javascript/prelude.mjs
class CustomType {
  withFields(fields) {
    let properties = Object.keys(this).map((label) => (label in fields) ? fields[label] : this[label]);
    return new this.constructor(...properties);
  }
}

class List {
  static fromArray(array, tail) {
    let t = tail || new Empty;
    for (let i = array.length - 1;i >= 0; --i) {
      t = new NonEmpty(array[i], t);
    }
    return t;
  }
  [Symbol.iterator]() {
    return new ListIterator(this);
  }
  toArray() {
    return [...this];
  }
  atLeastLength(desired) {
    let current = this;
    while (desired-- > 0 && current)
      current = current.tail;
    return current !== undefined;
  }
  hasLength(desired) {
    let current = this;
    while (desired-- > 0 && current)
      current = current.tail;
    return desired === -1 && current instanceof Empty;
  }
  countLength() {
    let current = this;
    let length = 0;
    while (current) {
      current = current.tail;
      length++;
    }
    return length - 1;
  }
}
function prepend(element, tail) {
  return new NonEmpty(element, tail);
}
function toList(elements, tail) {
  return List.fromArray(elements, tail);
}

class ListIterator {
  #current;
  constructor(current) {
    this.#current = current;
  }
  next() {
    if (this.#current instanceof Empty) {
      return { done: true };
    } else {
      let { head, tail } = this.#current;
      this.#current = tail;
      return { value: head, done: false };
    }
  }
}

class Empty extends List {
}
class NonEmpty extends List {
  constructor(head, tail) {
    super();
    this.head = head;
    this.tail = tail;
  }
}
var List$NonEmpty = (head, tail) => new NonEmpty(head, tail);
var List$isNonEmpty = (value) => value instanceof NonEmpty;
var List$NonEmpty$first = (value) => value.head;
var List$NonEmpty$rest = (value) => value.tail;

class BitArray {
  bitSize;
  byteSize;
  bitOffset;
  rawBuffer;
  constructor(buffer, bitSize, bitOffset) {
    if (!(buffer instanceof Uint8Array)) {
      throw globalThis.Error("BitArray can only be constructed from a Uint8Array");
    }
    this.bitSize = bitSize ?? buffer.length * 8;
    this.byteSize = Math.trunc((this.bitSize + 7) / 8);
    this.bitOffset = bitOffset ?? 0;
    if (this.bitSize < 0) {
      throw globalThis.Error(`BitArray bit size is invalid: ${this.bitSize}`);
    }
    if (this.bitOffset < 0 || this.bitOffset > 7) {
      throw globalThis.Error(`BitArray bit offset is invalid: ${this.bitOffset}`);
    }
    if (buffer.length !== Math.trunc((this.bitOffset + this.bitSize + 7) / 8)) {
      throw globalThis.Error("BitArray buffer length is invalid");
    }
    this.rawBuffer = buffer;
  }
  byteAt(index) {
    if (index < 0 || index >= this.byteSize) {
      return;
    }
    return bitArrayByteAt(this.rawBuffer, this.bitOffset, index);
  }
  equals(other) {
    if (this.bitSize !== other.bitSize) {
      return false;
    }
    const wholeByteCount = Math.trunc(this.bitSize / 8);
    if (this.bitOffset === 0 && other.bitOffset === 0) {
      for (let i = 0;i < wholeByteCount; i++) {
        if (this.rawBuffer[i] !== other.rawBuffer[i]) {
          return false;
        }
      }
      const trailingBitsCount = this.bitSize % 8;
      if (trailingBitsCount) {
        const unusedLowBitCount = 8 - trailingBitsCount;
        if (this.rawBuffer[wholeByteCount] >> unusedLowBitCount !== other.rawBuffer[wholeByteCount] >> unusedLowBitCount) {
          return false;
        }
      }
    } else {
      for (let i = 0;i < wholeByteCount; i++) {
        const a = bitArrayByteAt(this.rawBuffer, this.bitOffset, i);
        const b = bitArrayByteAt(other.rawBuffer, other.bitOffset, i);
        if (a !== b) {
          return false;
        }
      }
      const trailingBitsCount = this.bitSize % 8;
      if (trailingBitsCount) {
        const a = bitArrayByteAt(this.rawBuffer, this.bitOffset, wholeByteCount);
        const b = bitArrayByteAt(other.rawBuffer, other.bitOffset, wholeByteCount);
        const unusedLowBitCount = 8 - trailingBitsCount;
        if (a >> unusedLowBitCount !== b >> unusedLowBitCount) {
          return false;
        }
      }
    }
    return true;
  }
  get buffer() {
    bitArrayPrintDeprecationWarning("buffer", "Use BitArray.byteAt() or BitArray.rawBuffer instead");
    if (this.bitOffset !== 0 || this.bitSize % 8 !== 0) {
      throw new globalThis.Error("BitArray.buffer does not support unaligned bit arrays");
    }
    return this.rawBuffer;
  }
  get length() {
    bitArrayPrintDeprecationWarning("length", "Use BitArray.bitSize or BitArray.byteSize instead");
    if (this.bitOffset !== 0 || this.bitSize % 8 !== 0) {
      throw new globalThis.Error("BitArray.length does not support unaligned bit arrays");
    }
    return this.rawBuffer.length;
  }
}
function bitArrayByteAt(buffer, bitOffset, index) {
  if (bitOffset === 0) {
    return buffer[index] ?? 0;
  } else {
    const a = buffer[index] << bitOffset & 255;
    const b = buffer[index + 1] >> 8 - bitOffset;
    return a | b;
  }
}

class UtfCodepoint {
  constructor(value) {
    this.value = value;
  }
}
var isBitArrayDeprecationMessagePrinted = {};
function bitArrayPrintDeprecationWarning(name, message) {
  if (isBitArrayDeprecationMessagePrinted[name]) {
    return;
  }
  console.warn(`Deprecated BitArray.${name} property used in JavaScript FFI code. ${message}.`);
  isBitArrayDeprecationMessagePrinted[name] = true;
}
class Result extends CustomType {
  static isResult(data2) {
    return data2 instanceof Result;
  }
}

class Ok extends Result {
  constructor(value) {
    super();
    this[0] = value;
  }
  isOk() {
    return true;
  }
}
var Result$Ok = (value) => new Ok(value);
var Result$isOk = (value) => value instanceof Ok;
var Result$Ok$0 = (value) => value[0];

class Error extends Result {
  constructor(detail) {
    super();
    this[0] = detail;
  }
  isOk() {
    return false;
  }
}
var Result$Error = (detail) => new Error(detail);
function isEqual(x, y) {
  let values = [x, y];
  while (values.length) {
    let a = values.pop();
    let b = values.pop();
    if (a === b)
      continue;
    if (!isObject(a) || !isObject(b))
      return false;
    let unequal = !structurallyCompatibleObjects(a, b) || unequalDates(a, b) || unequalBuffers(a, b) || unequalArrays(a, b) || unequalMaps(a, b) || unequalSets(a, b) || unequalRegExps(a, b);
    if (unequal)
      return false;
    const proto = Object.getPrototypeOf(a);
    if (proto !== null && typeof proto.equals === "function") {
      try {
        if (a.equals(b))
          continue;
        else
          return false;
      } catch {}
    }
    let [keys, get] = getters(a);
    const ka = keys(a);
    const kb = keys(b);
    if (ka.length !== kb.length)
      return false;
    for (let k of ka) {
      values.push(get(a, k), get(b, k));
    }
  }
  return true;
}
function getters(object) {
  if (object instanceof Map) {
    return [(x) => x.keys(), (x, y) => x.get(y)];
  } else {
    let extra = object instanceof globalThis.Error ? ["message"] : [];
    return [(x) => [...extra, ...Object.keys(x)], (x, y) => x[y]];
  }
}
function unequalDates(a, b) {
  return a instanceof Date && (a > b || a < b);
}
function unequalBuffers(a, b) {
  return !(a instanceof BitArray) && a.buffer instanceof ArrayBuffer && a.BYTES_PER_ELEMENT && !(a.byteLength === b.byteLength && a.every((n, i) => n === b[i]));
}
function unequalArrays(a, b) {
  return Array.isArray(a) && a.length !== b.length;
}
function unequalMaps(a, b) {
  return a instanceof Map && a.size !== b.size;
}
function unequalSets(a, b) {
  return a instanceof Set && (a.size != b.size || [...a].some((e) => !b.has(e)));
}
function unequalRegExps(a, b) {
  return a instanceof RegExp && (a.source !== b.source || a.flags !== b.flags);
}
function isObject(a) {
  return typeof a === "object" && a !== null;
}
function structurallyCompatibleObjects(a, b) {
  if (typeof a !== "object" && typeof b !== "object" && (!a || !b))
    return false;
  let nonstructural = [Promise, WeakSet, WeakMap, Function];
  if (nonstructural.some((c) => a instanceof c))
    return false;
  return a.constructor === b.constructor;
}
function makeError(variant, file, module, line, fn, message, extra) {
  let error = new globalThis.Error(message);
  error.gleam_error = variant;
  error.file = file;
  error.module = module;
  error.line = line;
  error.function = fn;
  error.fn = fn;
  for (let k in extra)
    error[k] = extra[k];
  return error;
}
// build/dev/javascript/gleam_stdlib/gleam/order.mjs
class Lt extends CustomType {
}
var Order$Lt = () => new Lt;
class Eq extends CustomType {
}
var Order$Eq = () => new Eq;
class Gt extends CustomType {
}
var Order$Gt = () => new Gt;

// build/dev/javascript/gleam_stdlib/gleam/option.mjs
class Some extends CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
class None extends CustomType {
}
function from_result(result) {
  if (result instanceof Ok) {
    let a = result[0];
    return new Some(a);
  } else {
    return new None;
  }
}

// build/dev/javascript/gleam_stdlib/dict.mjs
var referenceMap = /* @__PURE__ */ new WeakMap;
var tempDataView = /* @__PURE__ */ new DataView(/* @__PURE__ */ new ArrayBuffer(8));
var referenceUID = 0;
function hashByReference(o) {
  const known = referenceMap.get(o);
  if (known !== undefined) {
    return known;
  }
  const hash = referenceUID++;
  if (referenceUID === 2147483647) {
    referenceUID = 0;
  }
  referenceMap.set(o, hash);
  return hash;
}
function hashMerge(a, b) {
  return a ^ b + 2654435769 + (a << 6) + (a >> 2) | 0;
}
function hashString(s) {
  let hash = 0;
  const len = s.length;
  for (let i = 0;i < len; i++) {
    hash = Math.imul(31, hash) + s.charCodeAt(i) | 0;
  }
  return hash;
}
function hashNumber(n) {
  tempDataView.setFloat64(0, n);
  const i = tempDataView.getInt32(0);
  const j = tempDataView.getInt32(4);
  return Math.imul(73244475, i >> 16 ^ i) ^ j;
}
function hashBigInt(n) {
  return hashString(n.toString());
}
function hashObject(o) {
  const proto = Object.getPrototypeOf(o);
  if (proto !== null && typeof proto.hashCode === "function") {
    try {
      const code = o.hashCode(o);
      if (typeof code === "number") {
        return code;
      }
    } catch {}
  }
  if (o instanceof Promise || o instanceof WeakSet || o instanceof WeakMap) {
    return hashByReference(o);
  }
  if (o instanceof Date) {
    return hashNumber(o.getTime());
  }
  let h = 0;
  if (o instanceof ArrayBuffer) {
    o = new Uint8Array(o);
  }
  if (Array.isArray(o) || o instanceof Uint8Array) {
    for (let i = 0;i < o.length; i++) {
      h = Math.imul(31, h) + getHash(o[i]) | 0;
    }
  } else if (o instanceof Set) {
    o.forEach((v) => {
      h = h + getHash(v) | 0;
    });
  } else if (o instanceof Map) {
    o.forEach((v, k) => {
      h = h + hashMerge(getHash(v), getHash(k)) | 0;
    });
  } else {
    const keys = Object.keys(o);
    for (let i = 0;i < keys.length; i++) {
      const k = keys[i];
      const v = o[k];
      h = h + hashMerge(getHash(v), hashString(k)) | 0;
    }
  }
  return h;
}
function getHash(u) {
  if (u === null)
    return 1108378658;
  if (u === undefined)
    return 1108378659;
  if (u === true)
    return 1108378657;
  if (u === false)
    return 1108378656;
  switch (typeof u) {
    case "number":
      return hashNumber(u);
    case "string":
      return hashString(u);
    case "bigint":
      return hashBigInt(u);
    case "object":
      return hashObject(u);
    case "symbol":
      return hashByReference(u);
    case "function":
      return hashByReference(u);
    default:
      return 0;
  }
}

class Dict {
  constructor(size, root) {
    this.size = size;
    this.root = root;
  }
}
var bits = 5;
var mask = (1 << bits) - 1;
var noElementMarker = Symbol();
var generationKey = Symbol();
var emptyNode = /* @__PURE__ */ newNode(0);
var emptyDict = /* @__PURE__ */ new Dict(0, emptyNode);
var errorNil = /* @__PURE__ */ Result$Error(undefined);
function makeNode(generation, datamap, nodemap, data2) {
  return {
    datamap,
    nodemap,
    data: data2,
    [generationKey]: generation
  };
}
function newNode(generation) {
  return makeNode(generation, 0, 0, []);
}
function copyNode(node, generation) {
  if (node[generationKey] === generation) {
    return node;
  }
  const newData = node.data.slice(0);
  return makeNode(generation, node.datamap, node.nodemap, newData);
}
function copyAndSet(node, generation, idx, val) {
  if (node.data[idx] === val) {
    return node;
  }
  node = copyNode(node, generation);
  node.data[idx] = val;
  return node;
}
function copyAndInsertPair(node, generation, bit, idx, key, val) {
  const data2 = node.data;
  const length = data2.length;
  const newData = new Array(length + 2);
  let readIndex = 0;
  let writeIndex = 0;
  while (readIndex < idx)
    newData[writeIndex++] = data2[readIndex++];
  newData[writeIndex++] = key;
  newData[writeIndex++] = val;
  while (readIndex < length)
    newData[writeIndex++] = data2[readIndex++];
  return makeNode(generation, node.datamap | bit, node.nodemap, newData);
}
function make() {
  return emptyDict;
}
function get(dict, key) {
  const result = lookup(dict.root, key, getHash(key));
  return result !== noElementMarker ? Result$Ok(result) : errorNil;
}
function lookup(node, key, hash) {
  for (let shift = 0;shift < 32; shift += bits) {
    const data2 = node.data;
    const bit = hashbit(hash, shift);
    if (node.nodemap & bit) {
      node = data2[data2.length - 1 - index(node.nodemap, bit)];
    } else if (node.datamap & bit) {
      const dataidx = Math.imul(index(node.datamap, bit), 2);
      return isEqual(key, data2[dataidx]) ? data2[dataidx + 1] : noElementMarker;
    } else {
      return noElementMarker;
    }
  }
  const overflow = node.data;
  for (let i = 0;i < overflow.length; i += 2) {
    if (isEqual(key, overflow[i])) {
      return overflow[i + 1];
    }
  }
  return noElementMarker;
}
function toTransient(dict) {
  return {
    generation: nextGeneration(dict),
    root: dict.root,
    size: dict.size,
    dict
  };
}
function nextGeneration(dict) {
  const root = dict.root;
  if (root[generationKey] < Number.MAX_SAFE_INTEGER) {
    return root[generationKey] + 1;
  }
  const queue = [root];
  while (queue.length) {
    const node = queue.pop();
    node[generationKey] = 0;
    const nodeStart = data.length - popcount(node.nodemap);
    for (let i = nodeStart;i < node.data.length; ++i) {
      queue.push(node.data[i]);
    }
  }
  return 1;
}
var globalTransient = /* @__PURE__ */ toTransient(emptyDict);
function insert(dict, key, value) {
  globalTransient.generation = nextGeneration(dict);
  globalTransient.size = dict.size;
  const hash = getHash(key);
  const root = insertIntoNode(globalTransient, dict.root, key, value, hash, 0);
  if (root === dict.root) {
    return dict;
  }
  return new Dict(globalTransient.size, root);
}
function insertIntoNode(transient, node, key, value, hash, shift) {
  const data2 = node.data;
  const generation = transient.generation;
  if (shift > 32) {
    for (let i = 0;i < data2.length; i += 2) {
      if (isEqual(key, data2[i])) {
        return copyAndSet(node, generation, i + 1, value);
      }
    }
    transient.size += 1;
    return copyAndInsertPair(node, generation, 0, data2.length, key, value);
  }
  const bit = hashbit(hash, shift);
  if (node.nodemap & bit) {
    const nodeidx2 = data2.length - 1 - index(node.nodemap, bit);
    let child2 = data2[nodeidx2];
    child2 = insertIntoNode(transient, child2, key, value, hash, shift + bits);
    return copyAndSet(node, generation, nodeidx2, child2);
  }
  const dataidx = Math.imul(index(node.datamap, bit), 2);
  if ((node.datamap & bit) === 0) {
    transient.size += 1;
    return copyAndInsertPair(node, generation, bit, dataidx, key, value);
  }
  if (isEqual(key, data2[dataidx])) {
    return copyAndSet(node, generation, dataidx + 1, value);
  }
  const childShift = shift + bits;
  let child = emptyNode;
  child = insertIntoNode(transient, child, key, value, hash, childShift);
  const key2 = data2[dataidx];
  const value2 = data2[dataidx + 1];
  const hash2 = getHash(key2);
  child = insertIntoNode(transient, child, key2, value2, hash2, childShift);
  transient.size -= 1;
  const length = data2.length;
  const nodeidx = length - 1 - index(node.nodemap, bit);
  const newData = new Array(length - 1);
  let readIndex = 0;
  let writeIndex = 0;
  while (readIndex < dataidx)
    newData[writeIndex++] = data2[readIndex++];
  readIndex += 2;
  while (readIndex <= nodeidx)
    newData[writeIndex++] = data2[readIndex++];
  newData[writeIndex++] = child;
  while (readIndex < length)
    newData[writeIndex++] = data2[readIndex++];
  return makeNode(generation, node.datamap ^ bit, node.nodemap | bit, newData);
}
function fold(dict, state, fun) {
  const queue = [dict.root];
  while (queue.length) {
    const node = queue.pop();
    const data2 = node.data;
    const edgesStart = data2.length - popcount(node.nodemap);
    for (let i = 0;i < edgesStart; i += 2) {
      state = fun(state, data2[i], data2[i + 1]);
    }
    for (let i = edgesStart;i < data2.length; ++i) {
      queue.push(data2[i]);
    }
  }
  return state;
}
function popcount(n) {
  n -= n >>> 1 & 1431655765;
  n = (n & 858993459) + (n >>> 2 & 858993459);
  return Math.imul(n + (n >>> 4) & 252645135, 16843009) >>> 24;
}
function index(bitmap, bit) {
  return popcount(bitmap & bit - 1);
}
function hashbit(hash, shift) {
  return 1 << (hash >>> shift & mask);
}

// build/dev/javascript/gleam_stdlib/gleam/dict.mjs
function keys(dict) {
  return fold(dict, toList([]), (acc, key, _) => {
    return prepend(key, acc);
  });
}

// build/dev/javascript/gleam_stdlib/gleam_stdlib.mjs
function identity(x) {
  return x;
}
function to_string(term) {
  return term.toString();
}
function graphemes(string) {
  const iterator = graphemes_iterator(string);
  if (iterator) {
    return List.fromArray(Array.from(iterator).map((item) => item.segment));
  } else {
    return List.fromArray(string.match(/./gsu));
  }
}
var segmenter = undefined;
function graphemes_iterator(string) {
  if (globalThis.Intl && Intl.Segmenter) {
    segmenter ||= new Intl.Segmenter;
    return segmenter.segment(string)[Symbol.iterator]();
  }
}
function split(xs, pattern) {
  return List.fromArray(xs.split(pattern));
}
function starts_with(haystack, needle) {
  return haystack.startsWith(needle);
}
var unicode_whitespaces = [
  " ",
  "\t",
  `
`,
  "\v",
  "\f",
  "\r",
  "",
  "\u2028",
  "\u2029"
].join("");
var trim_start_regex = /* @__PURE__ */ new RegExp(`^[${unicode_whitespaces}]*`);
var trim_end_regex = /* @__PURE__ */ new RegExp(`[${unicode_whitespaces}]*$`);
function classify_dynamic(data2) {
  if (typeof data2 === "string") {
    return "String";
  } else if (typeof data2 === "boolean") {
    return "Bool";
  } else if (data2 instanceof Result) {
    return "Result";
  } else if (data2 instanceof List) {
    return "List";
  } else if (data2 instanceof BitArray) {
    return "BitArray";
  } else if (data2 instanceof Dict) {
    return "Dict";
  } else if (Number.isInteger(data2)) {
    return "Int";
  } else if (Array.isArray(data2)) {
    return `Array`;
  } else if (typeof data2 === "number") {
    return "Float";
  } else if (data2 === null) {
    return "Nil";
  } else if (data2 === undefined) {
    return "Nil";
  } else {
    const type = typeof data2;
    return type.charAt(0).toUpperCase() + type.slice(1);
  }
}
function inspect(v) {
  return new Inspector().inspect(v);
}
function float_to_string(float) {
  const string = float.toString().replace("+", "");
  if (string.indexOf(".") >= 0) {
    return string;
  } else {
    const index2 = string.indexOf("e");
    if (index2 >= 0) {
      return string.slice(0, index2) + ".0" + string.slice(index2);
    } else {
      return string + ".0";
    }
  }
}

class Inspector {
  #references = new Set;
  inspect(v) {
    const t = typeof v;
    if (v === true)
      return "True";
    if (v === false)
      return "False";
    if (v === null)
      return "//js(null)";
    if (v === undefined)
      return "Nil";
    if (t === "string")
      return this.#string(v);
    if (t === "bigint" || Number.isInteger(v))
      return v.toString();
    if (t === "number")
      return float_to_string(v);
    if (v instanceof UtfCodepoint)
      return this.#utfCodepoint(v);
    if (v instanceof BitArray)
      return this.#bit_array(v);
    if (v instanceof RegExp)
      return `//js(${v})`;
    if (v instanceof Date)
      return `//js(Date("${v.toISOString()}"))`;
    if (v instanceof globalThis.Error)
      return `//js(${v.toString()})`;
    if (v instanceof Function) {
      const args = [];
      for (const i of Array(v.length).keys())
        args.push(String.fromCharCode(i + 97));
      return `//fn(${args.join(", ")}) { ... }`;
    }
    if (this.#references.size === this.#references.add(v).size) {
      return "//js(circular reference)";
    }
    let printed;
    if (Array.isArray(v)) {
      printed = `#(${v.map((v2) => this.inspect(v2)).join(", ")})`;
    } else if (v instanceof List) {
      printed = this.#list(v);
    } else if (v instanceof CustomType) {
      printed = this.#customType(v);
    } else if (v instanceof Dict) {
      printed = this.#dict(v);
    } else if (v instanceof Set) {
      return `//js(Set(${[...v].map((v2) => this.inspect(v2)).join(", ")}))`;
    } else {
      printed = this.#object(v);
    }
    this.#references.delete(v);
    return printed;
  }
  #object(v) {
    const name = Object.getPrototypeOf(v)?.constructor?.name || "Object";
    const props = [];
    for (const k of Object.keys(v)) {
      props.push(`${this.inspect(k)}: ${this.inspect(v[k])}`);
    }
    const body = props.length ? " " + props.join(", ") + " " : "";
    const head = name === "Object" ? "" : name + " ";
    return `//js(${head}{${body}})`;
  }
  #dict(map2) {
    let body = "dict.from_list([";
    let first = true;
    body = fold(map2, body, (body2, key, value) => {
      if (!first)
        body2 = body2 + ", ";
      first = false;
      return body2 + "#(" + this.inspect(key) + ", " + this.inspect(value) + ")";
    });
    return body + "])";
  }
  #customType(record) {
    const props = Object.keys(record).map((label) => {
      const value = this.inspect(record[label]);
      return isNaN(parseInt(label)) ? `${label}: ${value}` : value;
    }).join(", ");
    return props ? `${record.constructor.name}(${props})` : record.constructor.name;
  }
  #list(list) {
    if (list instanceof Empty) {
      return "[]";
    }
    let char_out = 'charlist.from_string("';
    let list_out = "[";
    let current = list;
    while (current instanceof NonEmpty) {
      let element = current.head;
      current = current.tail;
      if (list_out !== "[") {
        list_out += ", ";
      }
      list_out += this.inspect(element);
      if (char_out) {
        if (Number.isInteger(element) && element >= 32 && element <= 126) {
          char_out += String.fromCharCode(element);
        } else {
          char_out = null;
        }
      }
    }
    if (char_out) {
      return char_out + '")';
    } else {
      return list_out + "]";
    }
  }
  #string(str) {
    let new_str = '"';
    for (let i = 0;i < str.length; i++) {
      const char = str[i];
      switch (char) {
        case `
`:
          new_str += "\\n";
          break;
        case "\r":
          new_str += "\\r";
          break;
        case "\t":
          new_str += "\\t";
          break;
        case "\f":
          new_str += "\\f";
          break;
        case "\\":
          new_str += "\\\\";
          break;
        case '"':
          new_str += "\\\"";
          break;
        default:
          if (char < " " || char > "~" && char < " ") {
            new_str += "\\u{" + char.charCodeAt(0).toString(16).toUpperCase().padStart(4, "0") + "}";
          } else {
            new_str += char;
          }
      }
    }
    new_str += '"';
    return new_str;
  }
  #utfCodepoint(codepoint) {
    return `//utfcodepoint(${String.fromCodePoint(codepoint.value)})`;
  }
  #bit_array(bits2) {
    if (bits2.bitSize === 0) {
      return "<<>>";
    }
    let acc = "<<";
    for (let i = 0;i < bits2.byteSize - 1; i++) {
      acc += bits2.byteAt(i).toString();
      acc += ", ";
    }
    if (bits2.byteSize * 8 === bits2.bitSize) {
      acc += bits2.byteAt(bits2.byteSize - 1).toString();
    } else {
      const trailingBitsCount = bits2.bitSize % 8;
      acc += bits2.byteAt(bits2.byteSize - 1) >> 8 - trailingBitsCount;
      acc += `:size(${trailingBitsCount})`;
    }
    acc += ">>";
    return acc;
  }
}
function index2(data2, key) {
  if (data2 instanceof Dict) {
    const result = get(data2, key);
    return new Ok(result.isOk() ? new Some(result[0]) : new None);
  }
  if (data2 instanceof WeakMap || data2 instanceof Map) {
    const token = {};
    const entry = data2.get(key, token);
    if (entry === token)
      return new Ok(new None);
    return new Ok(new Some(entry));
  }
  const key_is_int = Number.isInteger(key);
  if (key_is_int && key >= 0 && key < 8 && data2 instanceof List) {
    let i = 0;
    for (const value of data2) {
      if (i === key)
        return new Ok(new Some(value));
      i++;
    }
    return new Error("Indexable");
  }
  if (key_is_int && Array.isArray(data2) || data2 && typeof data2 === "object" || data2 && Object.getPrototypeOf(data2) === Object.prototype) {
    if (key in data2)
      return new Ok(new Some(data2[key]));
    return new Ok(new None);
  }
  return new Error(key_is_int ? "Indexable" : "Dict");
}
function int(data2) {
  if (Number.isInteger(data2))
    return new Ok(data2);
  return new Error(0);
}
function string(data2) {
  if (typeof data2 === "string")
    return new Ok(data2);
  return new Error("");
}

// build/dev/javascript/gleam_stdlib/gleam/list.mjs
class Ascending extends CustomType {
}

class Descending extends CustomType {
}
function length_loop(loop$list, loop$count) {
  while (true) {
    let list = loop$list;
    let count = loop$count;
    if (list instanceof Empty) {
      return count;
    } else {
      let list$1 = list.tail;
      loop$list = list$1;
      loop$count = count + 1;
    }
  }
}
function length(list) {
  return length_loop(list, 0);
}
function reverse_and_prepend(loop$prefix, loop$suffix) {
  while (true) {
    let prefix = loop$prefix;
    let suffix = loop$suffix;
    if (prefix instanceof Empty) {
      return suffix;
    } else {
      let first$1 = prefix.head;
      let rest$1 = prefix.tail;
      loop$prefix = rest$1;
      loop$suffix = prepend(first$1, suffix);
    }
  }
}
function reverse(list) {
  return reverse_and_prepend(list, toList([]));
}
function filter_loop(loop$list, loop$fun, loop$acc) {
  while (true) {
    let list = loop$list;
    let fun = loop$fun;
    let acc = loop$acc;
    if (list instanceof Empty) {
      return reverse(acc);
    } else {
      let first$1 = list.head;
      let rest$1 = list.tail;
      let _block;
      let $ = fun(first$1);
      if ($) {
        _block = prepend(first$1, acc);
      } else {
        _block = acc;
      }
      let new_acc = _block;
      loop$list = rest$1;
      loop$fun = fun;
      loop$acc = new_acc;
    }
  }
}
function filter(list, predicate) {
  return filter_loop(list, predicate, toList([]));
}
function map_loop(loop$list, loop$fun, loop$acc) {
  while (true) {
    let list = loop$list;
    let fun = loop$fun;
    let acc = loop$acc;
    if (list instanceof Empty) {
      return reverse(acc);
    } else {
      let first$1 = list.head;
      let rest$1 = list.tail;
      loop$list = rest$1;
      loop$fun = fun;
      loop$acc = prepend(fun(first$1), acc);
    }
  }
}
function map2(list, fun) {
  return map_loop(list, fun, toList([]));
}
function index_map_loop(loop$list, loop$fun, loop$index, loop$acc) {
  while (true) {
    let list = loop$list;
    let fun = loop$fun;
    let index3 = loop$index;
    let acc = loop$acc;
    if (list instanceof Empty) {
      return reverse(acc);
    } else {
      let first$1 = list.head;
      let rest$1 = list.tail;
      let acc$1 = prepend(fun(first$1, index3), acc);
      loop$list = rest$1;
      loop$fun = fun;
      loop$index = index3 + 1;
      loop$acc = acc$1;
    }
  }
}
function index_map(list, fun) {
  return index_map_loop(list, fun, 0, toList([]));
}
function append_loop(loop$first, loop$second) {
  while (true) {
    let first = loop$first;
    let second = loop$second;
    if (first instanceof Empty) {
      return second;
    } else {
      let first$1 = first.head;
      let rest$1 = first.tail;
      loop$first = rest$1;
      loop$second = prepend(first$1, second);
    }
  }
}
function append(first, second) {
  return append_loop(reverse(first), second);
}
function prepend2(list, item) {
  return prepend(item, list);
}
function fold2(loop$list, loop$initial, loop$fun) {
  while (true) {
    let list = loop$list;
    let initial = loop$initial;
    let fun = loop$fun;
    if (list instanceof Empty) {
      return initial;
    } else {
      let first$1 = list.head;
      let rest$1 = list.tail;
      loop$list = rest$1;
      loop$initial = fun(initial, first$1);
      loop$fun = fun;
    }
  }
}
function find(loop$list, loop$is_desired) {
  while (true) {
    let list = loop$list;
    let is_desired = loop$is_desired;
    if (list instanceof Empty) {
      return new Error(undefined);
    } else {
      let first$1 = list.head;
      let rest$1 = list.tail;
      let $ = is_desired(first$1);
      if ($) {
        return new Ok(first$1);
      } else {
        loop$list = rest$1;
        loop$is_desired = is_desired;
      }
    }
  }
}
function sequences(loop$list, loop$compare, loop$growing, loop$direction, loop$prev, loop$acc) {
  while (true) {
    let list = loop$list;
    let compare3 = loop$compare;
    let growing = loop$growing;
    let direction = loop$direction;
    let prev = loop$prev;
    let acc = loop$acc;
    let growing$1 = prepend(prev, growing);
    if (list instanceof Empty) {
      if (direction instanceof Ascending) {
        return prepend(reverse(growing$1), acc);
      } else {
        return prepend(growing$1, acc);
      }
    } else {
      let new$1 = list.head;
      let rest$1 = list.tail;
      let $ = compare3(prev, new$1);
      if (direction instanceof Ascending) {
        if ($ instanceof Lt) {
          loop$list = rest$1;
          loop$compare = compare3;
          loop$growing = growing$1;
          loop$direction = direction;
          loop$prev = new$1;
          loop$acc = acc;
        } else if ($ instanceof Eq) {
          loop$list = rest$1;
          loop$compare = compare3;
          loop$growing = growing$1;
          loop$direction = direction;
          loop$prev = new$1;
          loop$acc = acc;
        } else {
          let _block;
          if (direction instanceof Ascending) {
            _block = prepend(reverse(growing$1), acc);
          } else {
            _block = prepend(growing$1, acc);
          }
          let acc$1 = _block;
          if (rest$1 instanceof Empty) {
            return prepend(toList([new$1]), acc$1);
          } else {
            let next = rest$1.head;
            let rest$2 = rest$1.tail;
            let _block$1;
            let $1 = compare3(new$1, next);
            if ($1 instanceof Lt) {
              _block$1 = new Ascending;
            } else if ($1 instanceof Eq) {
              _block$1 = new Ascending;
            } else {
              _block$1 = new Descending;
            }
            let direction$1 = _block$1;
            loop$list = rest$2;
            loop$compare = compare3;
            loop$growing = toList([new$1]);
            loop$direction = direction$1;
            loop$prev = next;
            loop$acc = acc$1;
          }
        }
      } else if ($ instanceof Lt) {
        let _block;
        if (direction instanceof Ascending) {
          _block = prepend(reverse(growing$1), acc);
        } else {
          _block = prepend(growing$1, acc);
        }
        let acc$1 = _block;
        if (rest$1 instanceof Empty) {
          return prepend(toList([new$1]), acc$1);
        } else {
          let next = rest$1.head;
          let rest$2 = rest$1.tail;
          let _block$1;
          let $1 = compare3(new$1, next);
          if ($1 instanceof Lt) {
            _block$1 = new Ascending;
          } else if ($1 instanceof Eq) {
            _block$1 = new Ascending;
          } else {
            _block$1 = new Descending;
          }
          let direction$1 = _block$1;
          loop$list = rest$2;
          loop$compare = compare3;
          loop$growing = toList([new$1]);
          loop$direction = direction$1;
          loop$prev = next;
          loop$acc = acc$1;
        }
      } else if ($ instanceof Eq) {
        let _block;
        if (direction instanceof Ascending) {
          _block = prepend(reverse(growing$1), acc);
        } else {
          _block = prepend(growing$1, acc);
        }
        let acc$1 = _block;
        if (rest$1 instanceof Empty) {
          return prepend(toList([new$1]), acc$1);
        } else {
          let next = rest$1.head;
          let rest$2 = rest$1.tail;
          let _block$1;
          let $1 = compare3(new$1, next);
          if ($1 instanceof Lt) {
            _block$1 = new Ascending;
          } else if ($1 instanceof Eq) {
            _block$1 = new Ascending;
          } else {
            _block$1 = new Descending;
          }
          let direction$1 = _block$1;
          loop$list = rest$2;
          loop$compare = compare3;
          loop$growing = toList([new$1]);
          loop$direction = direction$1;
          loop$prev = next;
          loop$acc = acc$1;
        }
      } else {
        loop$list = rest$1;
        loop$compare = compare3;
        loop$growing = growing$1;
        loop$direction = direction;
        loop$prev = new$1;
        loop$acc = acc;
      }
    }
  }
}
function merge_ascendings(loop$list1, loop$list2, loop$compare, loop$acc) {
  while (true) {
    let list1 = loop$list1;
    let list2 = loop$list2;
    let compare3 = loop$compare;
    let acc = loop$acc;
    if (list1 instanceof Empty) {
      let list = list2;
      return reverse_and_prepend(list, acc);
    } else if (list2 instanceof Empty) {
      let list = list1;
      return reverse_and_prepend(list, acc);
    } else {
      let first1 = list1.head;
      let rest1 = list1.tail;
      let first2 = list2.head;
      let rest2 = list2.tail;
      let $ = compare3(first1, first2);
      if ($ instanceof Lt) {
        loop$list1 = rest1;
        loop$list2 = list2;
        loop$compare = compare3;
        loop$acc = prepend(first1, acc);
      } else if ($ instanceof Eq) {
        loop$list1 = list1;
        loop$list2 = rest2;
        loop$compare = compare3;
        loop$acc = prepend(first2, acc);
      } else {
        loop$list1 = list1;
        loop$list2 = rest2;
        loop$compare = compare3;
        loop$acc = prepend(first2, acc);
      }
    }
  }
}
function merge_ascending_pairs(loop$sequences, loop$compare, loop$acc) {
  while (true) {
    let sequences2 = loop$sequences;
    let compare3 = loop$compare;
    let acc = loop$acc;
    if (sequences2 instanceof Empty) {
      return reverse(acc);
    } else {
      let $ = sequences2.tail;
      if ($ instanceof Empty) {
        let sequence = sequences2.head;
        return reverse(prepend(reverse(sequence), acc));
      } else {
        let ascending1 = sequences2.head;
        let ascending2 = $.head;
        let rest$1 = $.tail;
        let descending = merge_ascendings(ascending1, ascending2, compare3, toList([]));
        loop$sequences = rest$1;
        loop$compare = compare3;
        loop$acc = prepend(descending, acc);
      }
    }
  }
}
function merge_descendings(loop$list1, loop$list2, loop$compare, loop$acc) {
  while (true) {
    let list1 = loop$list1;
    let list2 = loop$list2;
    let compare3 = loop$compare;
    let acc = loop$acc;
    if (list1 instanceof Empty) {
      let list = list2;
      return reverse_and_prepend(list, acc);
    } else if (list2 instanceof Empty) {
      let list = list1;
      return reverse_and_prepend(list, acc);
    } else {
      let first1 = list1.head;
      let rest1 = list1.tail;
      let first2 = list2.head;
      let rest2 = list2.tail;
      let $ = compare3(first1, first2);
      if ($ instanceof Lt) {
        loop$list1 = list1;
        loop$list2 = rest2;
        loop$compare = compare3;
        loop$acc = prepend(first2, acc);
      } else if ($ instanceof Eq) {
        loop$list1 = rest1;
        loop$list2 = list2;
        loop$compare = compare3;
        loop$acc = prepend(first1, acc);
      } else {
        loop$list1 = rest1;
        loop$list2 = list2;
        loop$compare = compare3;
        loop$acc = prepend(first1, acc);
      }
    }
  }
}
function merge_descending_pairs(loop$sequences, loop$compare, loop$acc) {
  while (true) {
    let sequences2 = loop$sequences;
    let compare3 = loop$compare;
    let acc = loop$acc;
    if (sequences2 instanceof Empty) {
      return reverse(acc);
    } else {
      let $ = sequences2.tail;
      if ($ instanceof Empty) {
        let sequence = sequences2.head;
        return reverse(prepend(reverse(sequence), acc));
      } else {
        let descending1 = sequences2.head;
        let descending2 = $.head;
        let rest$1 = $.tail;
        let ascending = merge_descendings(descending1, descending2, compare3, toList([]));
        loop$sequences = rest$1;
        loop$compare = compare3;
        loop$acc = prepend(ascending, acc);
      }
    }
  }
}
function merge_all(loop$sequences, loop$direction, loop$compare) {
  while (true) {
    let sequences2 = loop$sequences;
    let direction = loop$direction;
    let compare3 = loop$compare;
    if (sequences2 instanceof Empty) {
      return sequences2;
    } else if (direction instanceof Ascending) {
      let $ = sequences2.tail;
      if ($ instanceof Empty) {
        let sequence = sequences2.head;
        return sequence;
      } else {
        let sequences$1 = merge_ascending_pairs(sequences2, compare3, toList([]));
        loop$sequences = sequences$1;
        loop$direction = new Descending;
        loop$compare = compare3;
      }
    } else {
      let $ = sequences2.tail;
      if ($ instanceof Empty) {
        let sequence = sequences2.head;
        return reverse(sequence);
      } else {
        let sequences$1 = merge_descending_pairs(sequences2, compare3, toList([]));
        loop$sequences = sequences$1;
        loop$direction = new Ascending;
        loop$compare = compare3;
      }
    }
  }
}
function sort(list, compare3) {
  if (list instanceof Empty) {
    return list;
  } else {
    let $ = list.tail;
    if ($ instanceof Empty) {
      return list;
    } else {
      let x = list.head;
      let y = $.head;
      let rest$1 = $.tail;
      let _block;
      let $1 = compare3(x, y);
      if ($1 instanceof Lt) {
        _block = new Ascending;
      } else if ($1 instanceof Eq) {
        _block = new Ascending;
      } else {
        _block = new Descending;
      }
      let direction = _block;
      let sequences$1 = sequences(rest$1, compare3, toList([x]), direction, y, toList([]));
      return merge_all(sequences$1, new Ascending, compare3);
    }
  }
}
function each(loop$list, loop$f) {
  while (true) {
    let list = loop$list;
    let f = loop$f;
    if (list instanceof Empty) {
      return;
    } else {
      let first$1 = list.head;
      let rest$1 = list.tail;
      f(first$1);
      loop$list = rest$1;
      loop$f = f;
    }
  }
}

// build/dev/javascript/gleam_stdlib/gleam/string.mjs
function concat_loop(loop$strings, loop$accumulator) {
  while (true) {
    let strings = loop$strings;
    let accumulator = loop$accumulator;
    if (strings instanceof Empty) {
      return accumulator;
    } else {
      let string2 = strings.head;
      let strings$1 = strings.tail;
      loop$strings = strings$1;
      loop$accumulator = accumulator + string2;
    }
  }
}
function concat2(strings) {
  return concat_loop(strings, "");
}
function split2(x, substring) {
  if (substring === "") {
    return graphemes(x);
  } else {
    let _pipe = x;
    let _pipe$1 = identity(_pipe);
    let _pipe$2 = split(_pipe$1, substring);
    return map2(_pipe$2, identity);
  }
}
function inspect2(term) {
  let _pipe = term;
  let _pipe$1 = inspect(_pipe);
  return identity(_pipe$1);
}

// build/dev/javascript/gleam_stdlib/gleam/dynamic/decode.mjs
class DecodeError extends CustomType {
  constructor(expected, found, path) {
    super();
    this.expected = expected;
    this.found = found;
    this.path = path;
  }
}
class Decoder extends CustomType {
  constructor(function$) {
    super();
    this.function = function$;
  }
}
var int2 = /* @__PURE__ */ new Decoder(decode_int);
var string2 = /* @__PURE__ */ new Decoder(decode_string);
function run(data2, decoder) {
  let $ = decoder.function(data2);
  let maybe_invalid_data;
  let errors;
  maybe_invalid_data = $[0];
  errors = $[1];
  if (errors instanceof Empty) {
    return new Ok(maybe_invalid_data);
  } else {
    return new Error(errors);
  }
}
function success(data2) {
  return new Decoder((_) => {
    return [data2, toList([])];
  });
}
function map3(decoder, transformer) {
  return new Decoder((d) => {
    let $ = decoder.function(d);
    let data2;
    let errors;
    data2 = $[0];
    errors = $[1];
    return [transformer(data2), errors];
  });
}
function then$(decoder, next) {
  return new Decoder((dynamic_data) => {
    let $ = decoder.function(dynamic_data);
    let data2;
    let errors;
    data2 = $[0];
    errors = $[1];
    let decoder$1 = next(data2);
    let $1 = decoder$1.function(dynamic_data);
    let layer;
    let data$1;
    layer = $1;
    data$1 = $1[0];
    if (errors instanceof Empty) {
      return layer;
    } else {
      return [data$1, errors];
    }
  });
}
function run_decoders(loop$data, loop$failure, loop$decoders) {
  while (true) {
    let data2 = loop$data;
    let failure = loop$failure;
    let decoders = loop$decoders;
    if (decoders instanceof Empty) {
      return failure;
    } else {
      let decoder = decoders.head;
      let decoders$1 = decoders.tail;
      let $ = decoder.function(data2);
      let layer;
      let errors;
      layer = $;
      errors = $[1];
      if (errors instanceof Empty) {
        return layer;
      } else {
        loop$data = data2;
        loop$failure = failure;
        loop$decoders = decoders$1;
      }
    }
  }
}
function one_of(first, alternatives) {
  return new Decoder((dynamic_data) => {
    let $ = first.function(dynamic_data);
    let layer;
    let errors;
    layer = $;
    errors = $[1];
    if (errors instanceof Empty) {
      return layer;
    } else {
      return run_decoders(dynamic_data, layer, alternatives);
    }
  });
}
function run_dynamic_function(data2, name, f) {
  let $ = f(data2);
  if ($ instanceof Ok) {
    let data$1 = $[0];
    return [data$1, toList([])];
  } else {
    let placeholder = $[0];
    return [
      placeholder,
      toList([new DecodeError(name, classify_dynamic(data2), toList([]))])
    ];
  }
}
function decode_int(data2) {
  return run_dynamic_function(data2, "Int", int);
}
function decode_string(data2) {
  return run_dynamic_function(data2, "String", string);
}
function push_path(layer, path) {
  let decoder = one_of(string2, toList([
    (() => {
      let _pipe = int2;
      return map3(_pipe, to_string);
    })()
  ]));
  let path$1 = map2(path, (key) => {
    let key$1 = identity(key);
    let $ = run(key$1, decoder);
    if ($ instanceof Ok) {
      let key$2 = $[0];
      return key$2;
    } else {
      return "<" + classify_dynamic(key$1) + ">";
    }
  });
  let errors = map2(layer[1], (error) => {
    return new DecodeError(error.expected, error.found, append(path$1, error.path));
  });
  return [layer[0], errors];
}
function index3(loop$path, loop$position, loop$inner, loop$data, loop$handle_miss) {
  while (true) {
    let path = loop$path;
    let position = loop$position;
    let inner = loop$inner;
    let data2 = loop$data;
    let handle_miss = loop$handle_miss;
    if (path instanceof Empty) {
      let _pipe = data2;
      let _pipe$1 = inner(_pipe);
      return push_path(_pipe$1, reverse(position));
    } else {
      let key = path.head;
      let path$1 = path.tail;
      let $ = index2(data2, key);
      if ($ instanceof Ok) {
        let $1 = $[0];
        if ($1 instanceof Some) {
          let data$1 = $1[0];
          loop$path = path$1;
          loop$position = prepend(key, position);
          loop$inner = inner;
          loop$data = data$1;
          loop$handle_miss = handle_miss;
        } else {
          return handle_miss(data2, prepend(key, position));
        }
      } else {
        let kind = $[0];
        let $1 = inner(data2);
        let default$;
        default$ = $1[0];
        let _pipe = [
          default$,
          toList([new DecodeError(kind, classify_dynamic(data2), toList([]))])
        ];
        return push_path(_pipe, reverse(position));
      }
    }
  }
}
function at(path, inner) {
  return new Decoder((data2) => {
    return index3(path, toList([]), inner.function, data2, (data3, position) => {
      let $ = inner.function(data3);
      let default$;
      default$ = $[0];
      let _pipe = [
        default$,
        toList([new DecodeError("Field", "Nothing", toList([]))])
      ];
      return push_path(_pipe, reverse(position));
    });
  });
}
// build/dev/javascript/gleam_stdlib/gleam/bool.mjs
function guard(requirement, consequence, alternative) {
  if (requirement) {
    return consequence;
  } else {
    return alternative();
  }
}

// build/dev/javascript/gleam_stdlib/gleam/function.mjs
function identity2(x) {
  return x;
}
// build/dev/javascript/gleam_json/gleam_json_ffi.mjs
function identity3(x) {
  return x;
}

// build/dev/javascript/gleam_json/gleam/json.mjs
function bool(input) {
  return identity3(input);
}

// build/dev/javascript/houdini/houdini.ffi.mjs
function do_escape(string3) {
  return string3.replaceAll(/[><&"']/g, (replaced) => {
    switch (replaced) {
      case ">":
        return "&gt;";
      case "<":
        return "&lt;";
      case "'":
        return "&#39;";
      case "&":
        return "&amp;";
      case '"':
        return "&quot;";
      default:
        return replaced;
    }
  });
}

// build/dev/javascript/houdini/houdini/internal/escape_js.mjs
function escape(text) {
  return do_escape(text);
}

// build/dev/javascript/houdini/houdini.mjs
function escape2(string3) {
  return escape(string3);
}

// build/dev/javascript/lustre/lustre/internals/constants.mjs
var empty_list = /* @__PURE__ */ toList([]);
var error_nil = /* @__PURE__ */ new Error(undefined);

// build/dev/javascript/lustre/lustre/vdom/vattr.ffi.mjs
var GT = /* @__PURE__ */ Order$Gt();
var LT = /* @__PURE__ */ Order$Lt();
var EQ = /* @__PURE__ */ Order$Eq();
function compare3(a, b) {
  if (a.name === b.name) {
    return EQ;
  } else if (a.name < b.name) {
    return LT;
  } else {
    return GT;
  }
}

// build/dev/javascript/lustre/lustre/vdom/vattr.mjs
class Attribute extends CustomType {
  constructor(kind, name, value) {
    super();
    this.kind = kind;
    this.name = name;
    this.value = value;
  }
}
class Property extends CustomType {
  constructor(kind, name, value) {
    super();
    this.kind = kind;
    this.name = name;
    this.value = value;
  }
}
class Event2 extends CustomType {
  constructor(kind, name, handler, include, prevent_default, stop_propagation, debounce, throttle) {
    super();
    this.kind = kind;
    this.name = name;
    this.handler = handler;
    this.include = include;
    this.prevent_default = prevent_default;
    this.stop_propagation = stop_propagation;
    this.debounce = debounce;
    this.throttle = throttle;
  }
}
class Handler extends CustomType {
  constructor(prevent_default, stop_propagation, message) {
    super();
    this.prevent_default = prevent_default;
    this.stop_propagation = stop_propagation;
    this.message = message;
  }
}
class Never extends CustomType {
  constructor(kind) {
    super();
    this.kind = kind;
  }
}
var attribute_kind = 0;
var property_kind = 1;
var event_kind = 2;
var never_kind = 0;
var never = /* @__PURE__ */ new Never(never_kind);
var always_kind = 2;
function merge(loop$attributes, loop$merged) {
  while (true) {
    let attributes = loop$attributes;
    let merged = loop$merged;
    if (attributes instanceof Empty) {
      return merged;
    } else {
      let $ = attributes.head;
      if ($ instanceof Attribute) {
        let $1 = $.name;
        if ($1 === "") {
          let rest = attributes.tail;
          loop$attributes = rest;
          loop$merged = merged;
        } else if ($1 === "class") {
          let $2 = $.value;
          if ($2 === "") {
            let rest = attributes.tail;
            loop$attributes = rest;
            loop$merged = merged;
          } else {
            let $3 = attributes.tail;
            if ($3 instanceof Empty) {
              let attribute$1 = $;
              let rest = $3;
              loop$attributes = rest;
              loop$merged = prepend(attribute$1, merged);
            } else {
              let $4 = $3.head;
              if ($4 instanceof Attribute) {
                let $5 = $4.name;
                if ($5 === "class") {
                  let kind = $.kind;
                  let class1 = $2;
                  let rest = $3.tail;
                  let class2 = $4.value;
                  let value = class1 + " " + class2;
                  let attribute$1 = new Attribute(kind, "class", value);
                  loop$attributes = prepend(attribute$1, rest);
                  loop$merged = merged;
                } else {
                  let attribute$1 = $;
                  let rest = $3;
                  loop$attributes = rest;
                  loop$merged = prepend(attribute$1, merged);
                }
              } else {
                let attribute$1 = $;
                let rest = $3;
                loop$attributes = rest;
                loop$merged = prepend(attribute$1, merged);
              }
            }
          }
        } else if ($1 === "style") {
          let $2 = $.value;
          if ($2 === "") {
            let rest = attributes.tail;
            loop$attributes = rest;
            loop$merged = merged;
          } else {
            let $3 = attributes.tail;
            if ($3 instanceof Empty) {
              let attribute$1 = $;
              let rest = $3;
              loop$attributes = rest;
              loop$merged = prepend(attribute$1, merged);
            } else {
              let $4 = $3.head;
              if ($4 instanceof Attribute) {
                let $5 = $4.name;
                if ($5 === "style") {
                  let kind = $.kind;
                  let style1 = $2;
                  let rest = $3.tail;
                  let style2 = $4.value;
                  let value = style1 + ";" + style2;
                  let attribute$1 = new Attribute(kind, "style", value);
                  loop$attributes = prepend(attribute$1, rest);
                  loop$merged = merged;
                } else {
                  let attribute$1 = $;
                  let rest = $3;
                  loop$attributes = rest;
                  loop$merged = prepend(attribute$1, merged);
                }
              } else {
                let attribute$1 = $;
                let rest = $3;
                loop$attributes = rest;
                loop$merged = prepend(attribute$1, merged);
              }
            }
          }
        } else {
          let attribute$1 = $;
          let rest = attributes.tail;
          loop$attributes = rest;
          loop$merged = prepend(attribute$1, merged);
        }
      } else {
        let attribute$1 = $;
        let rest = attributes.tail;
        loop$attributes = rest;
        loop$merged = prepend(attribute$1, merged);
      }
    }
  }
}
function prepare(attributes) {
  if (attributes instanceof Empty) {
    return attributes;
  } else {
    let $ = attributes.tail;
    if ($ instanceof Empty) {
      return attributes;
    } else {
      let _pipe = attributes;
      let _pipe$1 = sort(_pipe, (a, b) => {
        return compare3(b, a);
      });
      return merge(_pipe$1, empty_list);
    }
  }
}
function attribute(name, value) {
  return new Attribute(attribute_kind, name, value);
}
function property(name, value) {
  return new Property(property_kind, name, value);
}
function event(name, handler, include, prevent_default, stop_propagation, debounce, throttle) {
  return new Event2(event_kind, name, handler, include, prevent_default, stop_propagation, debounce, throttle);
}

// build/dev/javascript/lustre/lustre/attribute.mjs
function attribute2(name, value) {
  return attribute(name, value);
}
function property2(name, value) {
  return property(name, value);
}
function boolean_attribute(name, value) {
  if (value) {
    return attribute2(name, "");
  } else {
    return property2(name, bool(false));
  }
}
function class$(name) {
  return attribute2("class", name);
}
function checked(is_checked) {
  return boolean_attribute("checked", is_checked);
}
function name(element_name) {
  return attribute2("name", element_name);
}
function placeholder(text) {
  return attribute2("placeholder", text);
}
function type_(control_type) {
  return attribute2("type", control_type);
}
function value(control_value) {
  return attribute2("value", control_value);
}

// build/dev/javascript/lustre/lustre/effect.mjs
class Effect extends CustomType {
  constructor(synchronous, before_paint, after_paint) {
    super();
    this.synchronous = synchronous;
    this.before_paint = before_paint;
    this.after_paint = after_paint;
  }
}

class Actions extends CustomType {
  constructor(dispatch, emit, select, root, provide) {
    super();
    this.dispatch = dispatch;
    this.emit = emit;
    this.select = select;
    this.root = root;
    this.provide = provide;
  }
}
var empty = /* @__PURE__ */ new Effect(/* @__PURE__ */ toList([]), /* @__PURE__ */ toList([]), /* @__PURE__ */ toList([]));
function perform(effect, dispatch, emit, select, root, provide) {
  let actions = new Actions(dispatch, emit, select, root, provide);
  return each(effect.synchronous, (run2) => {
    return run2(actions);
  });
}
function none() {
  return empty;
}
function batch(effects) {
  return fold2(effects, empty, (acc, eff) => {
    return new Effect(fold2(eff.synchronous, acc.synchronous, prepend2), fold2(eff.before_paint, acc.before_paint, prepend2), fold2(eff.after_paint, acc.after_paint, prepend2));
  });
}

// build/dev/javascript/lustre/lustre/internals/mutable_map.ffi.mjs
function empty2() {
  return null;
}
function get2(map4, key) {
  return map4?.get(key);
}
function get_or_compute(map4, key, compute) {
  return map4?.get(key) ?? compute();
}
function has_key(map4, key) {
  return map4 && map4.has(key);
}
function insert2(map4, key, value2) {
  map4 ??= new Map;
  map4.set(key, value2);
  return map4;
}
function remove(map4, key) {
  map4?.delete(key);
  return map4;
}

// build/dev/javascript/lustre/lustre/internals/ref.ffi.mjs
function sameValueZero(x, y) {
  if (typeof x === "number" && typeof y === "number") {
    return x === y || x !== x && y !== y;
  }
  return x === y;
}

// build/dev/javascript/lustre/lustre/internals/ref.mjs
function equal_lists(loop$xs, loop$ys) {
  while (true) {
    let xs = loop$xs;
    let ys = loop$ys;
    if (xs instanceof Empty) {
      if (ys instanceof Empty) {
        return true;
      } else {
        return false;
      }
    } else if (ys instanceof Empty) {
      return false;
    } else {
      let x = xs.head;
      let xs$1 = xs.tail;
      let y = ys.head;
      let ys$1 = ys.tail;
      let $ = sameValueZero(x, y);
      if ($) {
        loop$xs = xs$1;
        loop$ys = ys$1;
      } else {
        return $;
      }
    }
  }
}

// build/dev/javascript/lustre/lustre/vdom/vnode.mjs
class Fragment extends CustomType {
  constructor(kind, key, children, keyed_children) {
    super();
    this.kind = kind;
    this.key = key;
    this.children = children;
    this.keyed_children = keyed_children;
  }
}
class Element extends CustomType {
  constructor(kind, key, namespace, tag, attributes, children, keyed_children, self_closing, void$) {
    super();
    this.kind = kind;
    this.key = key;
    this.namespace = namespace;
    this.tag = tag;
    this.attributes = attributes;
    this.children = children;
    this.keyed_children = keyed_children;
    this.self_closing = self_closing;
    this.void = void$;
  }
}
class Text extends CustomType {
  constructor(kind, key, content) {
    super();
    this.kind = kind;
    this.key = key;
    this.content = content;
  }
}
class UnsafeInnerHtml extends CustomType {
  constructor(kind, key, namespace, tag, attributes, inner_html) {
    super();
    this.kind = kind;
    this.key = key;
    this.namespace = namespace;
    this.tag = tag;
    this.attributes = attributes;
    this.inner_html = inner_html;
  }
}
class Map2 extends CustomType {
  constructor(kind, key, mapper, child) {
    super();
    this.kind = kind;
    this.key = key;
    this.mapper = mapper;
    this.child = child;
  }
}
class Memo extends CustomType {
  constructor(kind, key, dependencies, view) {
    super();
    this.kind = kind;
    this.key = key;
    this.dependencies = dependencies;
    this.view = view;
  }
}
var fragment_kind = 0;
var element_kind = 1;
var text_kind = 2;
var unsafe_inner_html_kind = 3;
var map_kind = 4;
var memo_kind = 5;
function is_void_html_element(tag, namespace) {
  if (namespace === "") {
    if (tag === "area") {
      return true;
    } else if (tag === "base") {
      return true;
    } else if (tag === "br") {
      return true;
    } else if (tag === "col") {
      return true;
    } else if (tag === "embed") {
      return true;
    } else if (tag === "hr") {
      return true;
    } else if (tag === "img") {
      return true;
    } else if (tag === "input") {
      return true;
    } else if (tag === "link") {
      return true;
    } else if (tag === "meta") {
      return true;
    } else if (tag === "param") {
      return true;
    } else if (tag === "source") {
      return true;
    } else if (tag === "track") {
      return true;
    } else if (tag === "wbr") {
      return true;
    } else {
      return false;
    }
  } else {
    return false;
  }
}
function to_keyed(key, node) {
  if (node instanceof Fragment) {
    return new Fragment(node.kind, key, node.children, node.keyed_children);
  } else if (node instanceof Element) {
    return new Element(node.kind, key, node.namespace, node.tag, node.attributes, node.children, node.keyed_children, node.self_closing, node.void);
  } else if (node instanceof Text) {
    return new Text(node.kind, key, node.content);
  } else if (node instanceof UnsafeInnerHtml) {
    return new UnsafeInnerHtml(node.kind, key, node.namespace, node.tag, node.attributes, node.inner_html);
  } else if (node instanceof Map2) {
    let child = node.child;
    return new Map2(node.kind, key, node.mapper, to_keyed(key, child));
  } else {
    let view = node.view;
    return new Memo(node.kind, key, node.dependencies, () => {
      return to_keyed(key, view());
    });
  }
}
function fragment(key, children, keyed_children) {
  return new Fragment(fragment_kind, key, children, keyed_children);
}
function element(key, namespace, tag, attributes, children, keyed_children, self_closing, void$) {
  return new Element(element_kind, key, namespace, tag, prepare(attributes), children, keyed_children, self_closing, void$);
}
function text(key, content) {
  return new Text(text_kind, key, content);
}
function map4(element2, mapper) {
  if (element2 instanceof Map2) {
    let child_mapper = element2.mapper;
    return new Map2(map_kind, element2.key, (handler) => {
      return identity2(mapper)(child_mapper(handler));
    }, identity2(element2.child));
  } else {
    return new Map2(map_kind, element2.key, identity2(mapper), identity2(element2));
  }
}
function memo(key, dependencies, view) {
  return new Memo(memo_kind, key, dependencies, view);
}

// build/dev/javascript/lustre/lustre/element.mjs
function element2(tag, attributes, children) {
  return element("", "", tag, attributes, children, empty2(), false, is_void_html_element(tag, ""));
}
function text2(content) {
  return text("", content);
}
function none2() {
  return text("", "");
}
function fragment2(children) {
  return fragment("", children, empty2());
}
function memo2(dependencies, view) {
  return memo("", dependencies, view);
}
function ref(value2) {
  return identity2(value2);
}
function map5(element3, f) {
  return map4(element3, f);
}

// build/dev/javascript/lustre/lustre/element/html.mjs
function text3(content) {
  return text2(content);
}
function aside(attrs, children) {
  return element2("aside", attrs, children);
}
function header(attrs, children) {
  return element2("header", attrs, children);
}
function h1(attrs, children) {
  return element2("h1", attrs, children);
}
function h2(attrs, children) {
  return element2("h2", attrs, children);
}
function h3(attrs, children) {
  return element2("h3", attrs, children);
}
function main(attrs, children) {
  return element2("main", attrs, children);
}
function nav(attrs, children) {
  return element2("nav", attrs, children);
}
function div(attrs, children) {
  return element2("div", attrs, children);
}
function li(attrs, children) {
  return element2("li", attrs, children);
}
function p(attrs, children) {
  return element2("p", attrs, children);
}
function ul(attrs, children) {
  return element2("ul", attrs, children);
}
function span(attrs, children) {
  return element2("span", attrs, children);
}
function button(attrs, children) {
  return element2("button", attrs, children);
}
function input(attrs) {
  return element2("input", attrs, empty_list);
}
function label(attrs, children) {
  return element2("label", attrs, children);
}

// build/dev/javascript/lustre/lustre/vdom/patch.mjs
class Patch extends CustomType {
  constructor(index4, removed, changes, children) {
    super();
    this.index = index4;
    this.removed = removed;
    this.changes = changes;
    this.children = children;
  }
}
class ReplaceText extends CustomType {
  constructor(kind, content) {
    super();
    this.kind = kind;
    this.content = content;
  }
}
class ReplaceInnerHtml extends CustomType {
  constructor(kind, inner_html) {
    super();
    this.kind = kind;
    this.inner_html = inner_html;
  }
}
class Update extends CustomType {
  constructor(kind, added, removed) {
    super();
    this.kind = kind;
    this.added = added;
    this.removed = removed;
  }
}
class Move extends CustomType {
  constructor(kind, key, before) {
    super();
    this.kind = kind;
    this.key = key;
    this.before = before;
  }
}
class Replace extends CustomType {
  constructor(kind, index4, with$) {
    super();
    this.kind = kind;
    this.index = index4;
    this.with = with$;
  }
}
class Remove extends CustomType {
  constructor(kind, index4) {
    super();
    this.kind = kind;
    this.index = index4;
  }
}
class Insert extends CustomType {
  constructor(kind, children, before) {
    super();
    this.kind = kind;
    this.children = children;
    this.before = before;
  }
}
var replace_text_kind = 0;
var replace_inner_html_kind = 1;
var update_kind = 2;
var move_kind = 3;
var remove_kind = 4;
var replace_kind = 5;
var insert_kind = 6;
function new$3(index4, removed, changes, children) {
  return new Patch(index4, removed, changes, children);
}
function replace_text(content) {
  return new ReplaceText(replace_text_kind, content);
}
function replace_inner_html(inner_html) {
  return new ReplaceInnerHtml(replace_inner_html_kind, inner_html);
}
function update(added, removed) {
  return new Update(update_kind, added, removed);
}
function move(key, before) {
  return new Move(move_kind, key, before);
}
function remove2(index4) {
  return new Remove(remove_kind, index4);
}
function replace2(index4, with$) {
  return new Replace(replace_kind, index4, with$);
}
function insert3(children, before) {
  return new Insert(insert_kind, children, before);
}

// build/dev/javascript/lustre/lustre/runtime/transport.mjs
class Mount extends CustomType {
  constructor(kind, open_shadow_root, will_adopt_styles, observed_attributes, observed_properties, requested_contexts, provided_contexts, vdom, memos) {
    super();
    this.kind = kind;
    this.open_shadow_root = open_shadow_root;
    this.will_adopt_styles = will_adopt_styles;
    this.observed_attributes = observed_attributes;
    this.observed_properties = observed_properties;
    this.requested_contexts = requested_contexts;
    this.provided_contexts = provided_contexts;
    this.vdom = vdom;
    this.memos = memos;
  }
}
class Reconcile extends CustomType {
  constructor(kind, patch, memos) {
    super();
    this.kind = kind;
    this.patch = patch;
    this.memos = memos;
  }
}
class Emit extends CustomType {
  constructor(kind, name2, data2) {
    super();
    this.kind = kind;
    this.name = name2;
    this.data = data2;
  }
}
class Provide extends CustomType {
  constructor(kind, key, value2) {
    super();
    this.kind = kind;
    this.key = key;
    this.value = value2;
  }
}
class Batch extends CustomType {
  constructor(kind, messages) {
    super();
    this.kind = kind;
    this.messages = messages;
  }
}
var ServerMessage$isBatch = (value2) => value2 instanceof Batch;
class AttributeChanged extends CustomType {
  constructor(kind, name2, value2) {
    super();
    this.kind = kind;
    this.name = name2;
    this.value = value2;
  }
}
var ServerMessage$isAttributeChanged = (value2) => value2 instanceof AttributeChanged;
class PropertyChanged extends CustomType {
  constructor(kind, name2, value2) {
    super();
    this.kind = kind;
    this.name = name2;
    this.value = value2;
  }
}
var ServerMessage$isPropertyChanged = (value2) => value2 instanceof PropertyChanged;
class EventFired extends CustomType {
  constructor(kind, path, name2, event2) {
    super();
    this.kind = kind;
    this.path = path;
    this.name = name2;
    this.event = event2;
  }
}
var ServerMessage$isEventFired = (value2) => value2 instanceof EventFired;
class ContextProvided extends CustomType {
  constructor(kind, key, value2) {
    super();
    this.kind = kind;
    this.key = key;
    this.value = value2;
  }
}
var ServerMessage$isContextProvided = (value2) => value2 instanceof ContextProvided;
var mount_kind = 0;
var reconcile_kind = 1;
var emit_kind = 2;
var provide_kind = 3;
function mount(open_shadow_root, will_adopt_styles, observed_attributes, observed_properties, requested_contexts, provided_contexts, vdom, memos) {
  return new Mount(mount_kind, open_shadow_root, will_adopt_styles, observed_attributes, observed_properties, requested_contexts, provided_contexts, vdom, memos);
}
function reconcile(patch, memos) {
  return new Reconcile(reconcile_kind, patch, memos);
}
function emit(name2, data2) {
  return new Emit(emit_kind, name2, data2);
}
function provide(key, value2) {
  return new Provide(provide_kind, key, value2);
}

// build/dev/javascript/lustre/lustre/vdom/path.mjs
class Root extends CustomType {
}

class Key extends CustomType {
  constructor(key, parent) {
    super();
    this.key = key;
    this.parent = parent;
  }
}

class Index extends CustomType {
  constructor(index4, parent) {
    super();
    this.index = index4;
    this.parent = parent;
  }
}

class Subtree extends CustomType {
  constructor(parent) {
    super();
    this.parent = parent;
  }
}
var root = /* @__PURE__ */ new Root;
var separator_element = "\t";
var separator_subtree = "\r";
var separator_event = `
`;
function do_matches(loop$path, loop$candidates) {
  while (true) {
    let path = loop$path;
    let candidates = loop$candidates;
    if (candidates instanceof Empty) {
      return false;
    } else {
      let candidate = candidates.head;
      let rest = candidates.tail;
      let $ = starts_with(path, candidate);
      if ($) {
        return $;
      } else {
        loop$path = path;
        loop$candidates = rest;
      }
    }
  }
}
function add2(parent, index4, key) {
  if (key === "") {
    return new Index(index4, parent);
  } else {
    return new Key(key, parent);
  }
}
function subtree(path) {
  return new Subtree(path);
}
function finish_to_string(acc) {
  if (acc instanceof Empty) {
    return "";
  } else {
    let segments = acc.tail;
    return concat2(segments);
  }
}
function split_subtree_path(path) {
  return split2(path, separator_subtree);
}
function do_to_string(loop$full, loop$path, loop$acc) {
  while (true) {
    let full = loop$full;
    let path = loop$path;
    let acc = loop$acc;
    if (path instanceof Root) {
      return finish_to_string(acc);
    } else if (path instanceof Key) {
      let key = path.key;
      let parent = path.parent;
      loop$full = full;
      loop$path = parent;
      loop$acc = prepend(separator_element, prepend(key, acc));
    } else if (path instanceof Index) {
      let index4 = path.index;
      let parent = path.parent;
      let acc$1 = prepend(separator_element, prepend(to_string(index4), acc));
      loop$full = full;
      loop$path = parent;
      loop$acc = acc$1;
    } else if (!full) {
      return finish_to_string(acc);
    } else {
      let parent = path.parent;
      if (acc instanceof Empty) {
        loop$full = full;
        loop$path = parent;
        loop$acc = acc;
      } else {
        let acc$1 = acc.tail;
        loop$full = full;
        loop$path = parent;
        loop$acc = prepend(separator_subtree, acc$1);
      }
    }
  }
}
function child(path) {
  return do_to_string(false, path, empty_list);
}
function to_string3(path) {
  return do_to_string(true, path, empty_list);
}
function matches(path, candidates) {
  if (candidates instanceof Empty) {
    return false;
  } else {
    return do_matches(to_string3(path), candidates);
  }
}
function event2(path, event3) {
  return do_to_string(false, path, prepend(separator_event, prepend(event3, empty_list)));
}

// build/dev/javascript/lustre/lustre/vdom/cache.mjs
class Cache extends CustomType {
  constructor(events, vdoms, old_vdoms, dispatched_paths, next_dispatched_paths) {
    super();
    this.events = events;
    this.vdoms = vdoms;
    this.old_vdoms = old_vdoms;
    this.dispatched_paths = dispatched_paths;
    this.next_dispatched_paths = next_dispatched_paths;
  }
}

class Events extends CustomType {
  constructor(handlers, children) {
    super();
    this.handlers = handlers;
    this.children = children;
  }
}

class Child extends CustomType {
  constructor(mapper, events) {
    super();
    this.mapper = mapper;
    this.events = events;
  }
}

class AddedChildren extends CustomType {
  constructor(handlers, children, vdoms) {
    super();
    this.handlers = handlers;
    this.children = children;
    this.vdoms = vdoms;
  }
}

class DecodedEvent extends CustomType {
  constructor(path, handler) {
    super();
    this.path = path;
    this.handler = handler;
  }
}

class DispatchedEvent extends CustomType {
  constructor(path) {
    super();
    this.path = path;
  }
}
function compose_mapper(mapper, child_mapper) {
  return (msg) => {
    return mapper(child_mapper(msg));
  };
}
function new_events() {
  return new Events(empty2(), empty2());
}
function new$4() {
  return new Cache(new_events(), empty2(), empty2(), empty_list, empty_list);
}
function tick(cache) {
  return new Cache(cache.events, empty2(), cache.vdoms, cache.next_dispatched_paths, empty_list);
}
function events(cache) {
  return cache.events;
}
function update_events(cache, events2) {
  return new Cache(events2, cache.vdoms, cache.old_vdoms, cache.dispatched_paths, cache.next_dispatched_paths);
}
function memos(cache) {
  return cache.vdoms;
}
function get_old_memo(cache, old, new$5) {
  return get_or_compute(cache.old_vdoms, old, new$5);
}
function keep_memo(cache, old, new$5) {
  let node = get_or_compute(cache.old_vdoms, old, new$5);
  let vdoms = insert2(cache.vdoms, new$5, node);
  return new Cache(cache.events, vdoms, cache.old_vdoms, cache.dispatched_paths, cache.next_dispatched_paths);
}
function add_memo(cache, new$5, node) {
  let vdoms = insert2(cache.vdoms, new$5, node);
  return new Cache(cache.events, vdoms, cache.old_vdoms, cache.dispatched_paths, cache.next_dispatched_paths);
}
function get_subtree(events2, path, old_mapper) {
  let child2 = get_or_compute(events2.children, path, () => {
    return new Child(old_mapper, new_events());
  });
  return child2.events;
}
function update_subtree(parent, path, mapper, events2) {
  let new_child = new Child(mapper, events2);
  let children = insert2(parent.children, path, new_child);
  return new Events(parent.handlers, children);
}
function do_add_event(handlers, path, name2, handler) {
  return insert2(handlers, event2(path, name2), handler);
}
function add_event(events2, path, name2, handler) {
  let handlers = do_add_event(events2.handlers, path, name2, handler);
  return new Events(handlers, events2.children);
}
function do_remove_event(handlers, path, name2) {
  return remove(handlers, event2(path, name2));
}
function remove_event(events2, path, name2) {
  let handlers = do_remove_event(events2.handlers, path, name2);
  return new Events(handlers, events2.children);
}
function add_attributes(handlers, path, attributes) {
  return fold2(attributes, handlers, (events2, attribute3) => {
    if (attribute3 instanceof Event2) {
      let name2 = attribute3.name;
      let handler = attribute3.handler;
      return do_add_event(events2, path, name2, handler);
    } else {
      return events2;
    }
  });
}
function do_add_children(loop$handlers, loop$children, loop$vdoms, loop$parent, loop$child_index, loop$nodes) {
  while (true) {
    let handlers = loop$handlers;
    let children = loop$children;
    let vdoms = loop$vdoms;
    let parent = loop$parent;
    let child_index = loop$child_index;
    let nodes = loop$nodes;
    let next = child_index + 1;
    if (nodes instanceof Empty) {
      return new AddedChildren(handlers, children, vdoms);
    } else {
      let $ = nodes.head;
      if ($ instanceof Fragment) {
        let rest = nodes.tail;
        let key = $.key;
        let nodes$1 = $.children;
        let path = add2(parent, child_index, key);
        let $1 = do_add_children(handlers, children, vdoms, path, 0, nodes$1);
        let handlers$1;
        let children$1;
        let vdoms$1;
        handlers$1 = $1.handlers;
        children$1 = $1.children;
        vdoms$1 = $1.vdoms;
        loop$handlers = handlers$1;
        loop$children = children$1;
        loop$vdoms = vdoms$1;
        loop$parent = parent;
        loop$child_index = next;
        loop$nodes = rest;
      } else if ($ instanceof Element) {
        let rest = nodes.tail;
        let key = $.key;
        let attributes = $.attributes;
        let nodes$1 = $.children;
        let path = add2(parent, child_index, key);
        let handlers$1 = add_attributes(handlers, path, attributes);
        let $1 = do_add_children(handlers$1, children, vdoms, path, 0, nodes$1);
        let handlers$2;
        let children$1;
        let vdoms$1;
        handlers$2 = $1.handlers;
        children$1 = $1.children;
        vdoms$1 = $1.vdoms;
        loop$handlers = handlers$2;
        loop$children = children$1;
        loop$vdoms = vdoms$1;
        loop$parent = parent;
        loop$child_index = next;
        loop$nodes = rest;
      } else if ($ instanceof Text) {
        let rest = nodes.tail;
        loop$handlers = handlers;
        loop$children = children;
        loop$vdoms = vdoms;
        loop$parent = parent;
        loop$child_index = next;
        loop$nodes = rest;
      } else if ($ instanceof UnsafeInnerHtml) {
        let rest = nodes.tail;
        let key = $.key;
        let attributes = $.attributes;
        let path = add2(parent, child_index, key);
        let handlers$1 = add_attributes(handlers, path, attributes);
        loop$handlers = handlers$1;
        loop$children = children;
        loop$vdoms = vdoms;
        loop$parent = parent;
        loop$child_index = next;
        loop$nodes = rest;
      } else if ($ instanceof Map2) {
        let rest = nodes.tail;
        let key = $.key;
        let mapper = $.mapper;
        let child2 = $.child;
        let path = add2(parent, child_index, key);
        let added = do_add_children(empty2(), empty2(), vdoms, subtree(path), 0, prepend(child2, empty_list));
        let vdoms$1 = added.vdoms;
        let child_events = new Events(added.handlers, added.children);
        let child$1 = new Child(mapper, child_events);
        let children$1 = insert2(children, child(path), child$1);
        loop$handlers = handlers;
        loop$children = children$1;
        loop$vdoms = vdoms$1;
        loop$parent = parent;
        loop$child_index = next;
        loop$nodes = rest;
      } else {
        let rest = nodes.tail;
        let view = $.view;
        let child_node = view();
        let vdoms$1 = insert2(vdoms, view, child_node);
        let next$1 = child_index;
        let rest$1 = prepend(child_node, rest);
        loop$handlers = handlers;
        loop$children = children;
        loop$vdoms = vdoms$1;
        loop$parent = parent;
        loop$child_index = next$1;
        loop$nodes = rest$1;
      }
    }
  }
}
function add_children(cache, events2, path, child_index, nodes) {
  let vdoms = cache.vdoms;
  let handlers;
  let children;
  handlers = events2.handlers;
  children = events2.children;
  let $ = do_add_children(handlers, children, vdoms, path, child_index, nodes);
  let handlers$1;
  let children$1;
  let vdoms$1;
  handlers$1 = $.handlers;
  children$1 = $.children;
  vdoms$1 = $.vdoms;
  return [
    new Cache(cache.events, vdoms$1, cache.old_vdoms, cache.dispatched_paths, cache.next_dispatched_paths),
    new Events(handlers$1, children$1)
  ];
}
function add_child(cache, events2, parent, index4, child2) {
  let children = prepend(child2, empty_list);
  return add_children(cache, events2, parent, index4, children);
}
function from_node(root2) {
  let cache = new$4();
  let $ = add_child(cache, cache.events, root, 0, root2);
  let cache$1;
  let events$1;
  cache$1 = $[0];
  events$1 = $[1];
  return new Cache(events$1, cache$1.vdoms, cache$1.old_vdoms, cache$1.dispatched_paths, cache$1.next_dispatched_paths);
}
function remove_attributes(handlers, path, attributes) {
  return fold2(attributes, handlers, (events2, attribute3) => {
    if (attribute3 instanceof Event2) {
      let name2 = attribute3.name;
      return do_remove_event(events2, path, name2);
    } else {
      return events2;
    }
  });
}
function do_remove_children(loop$handlers, loop$children, loop$vdoms, loop$parent, loop$index, loop$nodes) {
  while (true) {
    let handlers = loop$handlers;
    let children = loop$children;
    let vdoms = loop$vdoms;
    let parent = loop$parent;
    let index4 = loop$index;
    let nodes = loop$nodes;
    let next = index4 + 1;
    if (nodes instanceof Empty) {
      return new Events(handlers, children);
    } else {
      let $ = nodes.head;
      if ($ instanceof Fragment) {
        let rest = nodes.tail;
        let key = $.key;
        let nodes$1 = $.children;
        let path = add2(parent, index4, key);
        let $1 = do_remove_children(handlers, children, vdoms, path, 0, nodes$1);
        let handlers$1;
        let children$1;
        handlers$1 = $1.handlers;
        children$1 = $1.children;
        loop$handlers = handlers$1;
        loop$children = children$1;
        loop$vdoms = vdoms;
        loop$parent = parent;
        loop$index = next;
        loop$nodes = rest;
      } else if ($ instanceof Element) {
        let rest = nodes.tail;
        let key = $.key;
        let attributes = $.attributes;
        let nodes$1 = $.children;
        let path = add2(parent, index4, key);
        let handlers$1 = remove_attributes(handlers, path, attributes);
        let $1 = do_remove_children(handlers$1, children, vdoms, path, 0, nodes$1);
        let handlers$2;
        let children$1;
        handlers$2 = $1.handlers;
        children$1 = $1.children;
        loop$handlers = handlers$2;
        loop$children = children$1;
        loop$vdoms = vdoms;
        loop$parent = parent;
        loop$index = next;
        loop$nodes = rest;
      } else if ($ instanceof Text) {
        let rest = nodes.tail;
        loop$handlers = handlers;
        loop$children = children;
        loop$vdoms = vdoms;
        loop$parent = parent;
        loop$index = next;
        loop$nodes = rest;
      } else if ($ instanceof UnsafeInnerHtml) {
        let rest = nodes.tail;
        let key = $.key;
        let attributes = $.attributes;
        let path = add2(parent, index4, key);
        let handlers$1 = remove_attributes(handlers, path, attributes);
        loop$handlers = handlers$1;
        loop$children = children;
        loop$vdoms = vdoms;
        loop$parent = parent;
        loop$index = next;
        loop$nodes = rest;
      } else if ($ instanceof Map2) {
        let rest = nodes.tail;
        let key = $.key;
        let path = add2(parent, index4, key);
        let children$1 = remove(children, child(path));
        loop$handlers = handlers;
        loop$children = children$1;
        loop$vdoms = vdoms;
        loop$parent = parent;
        loop$index = next;
        loop$nodes = rest;
      } else {
        let rest = nodes.tail;
        let view = $.view;
        let $1 = has_key(vdoms, view);
        if ($1) {
          let child2 = get2(vdoms, view);
          let nodes$1 = prepend(child2, rest);
          loop$handlers = handlers;
          loop$children = children;
          loop$vdoms = vdoms;
          loop$parent = parent;
          loop$index = index4;
          loop$nodes = nodes$1;
        } else {
          loop$handlers = handlers;
          loop$children = children;
          loop$vdoms = vdoms;
          loop$parent = parent;
          loop$index = next;
          loop$nodes = rest;
        }
      }
    }
  }
}
function remove_child(cache, events2, parent, child_index, child2) {
  return do_remove_children(events2.handlers, events2.children, cache.old_vdoms, parent, child_index, prepend(child2, empty_list));
}
function replace_child(cache, events2, parent, child_index, prev, next) {
  let events$1 = remove_child(cache, events2, parent, child_index, prev);
  return add_child(cache, events$1, parent, child_index, next);
}
function dispatch(cache, event3) {
  let next_dispatched_paths = prepend(event3.path, cache.next_dispatched_paths);
  let cache$1 = new Cache(cache.events, cache.vdoms, cache.old_vdoms, cache.dispatched_paths, next_dispatched_paths);
  if (event3 instanceof DecodedEvent) {
    let handler = event3.handler;
    return [cache$1, new Ok(handler)];
  } else {
    return [cache$1, error_nil];
  }
}
function has_dispatched_events(cache, path) {
  return matches(path, cache.dispatched_paths);
}
function get_handler(loop$events, loop$path, loop$mapper) {
  while (true) {
    let events2 = loop$events;
    let path = loop$path;
    let mapper = loop$mapper;
    if (path instanceof Empty) {
      return error_nil;
    } else {
      let $ = path.tail;
      if ($ instanceof Empty) {
        let key = path.head;
        let $1 = has_key(events2.handlers, key);
        if ($1) {
          let handler = get2(events2.handlers, key);
          return new Ok(map3(handler, (handler2) => {
            return new Handler(handler2.prevent_default, handler2.stop_propagation, identity2(mapper)(handler2.message));
          }));
        } else {
          return error_nil;
        }
      } else {
        let key = path.head;
        let path$1 = $;
        let $1 = has_key(events2.children, key);
        if ($1) {
          let child2 = get2(events2.children, key);
          let mapper$1 = compose_mapper(mapper, child2.mapper);
          loop$events = child2.events;
          loop$path = path$1;
          loop$mapper = mapper$1;
        } else {
          return error_nil;
        }
      }
    }
  }
}
function decode2(cache, path, name2, event3) {
  let parts = split_subtree_path(path + separator_event + name2);
  let $ = get_handler(cache.events, parts, identity2);
  if ($ instanceof Ok) {
    let handler = $[0];
    let $1 = run(event3, handler);
    if ($1 instanceof Ok) {
      let handler$1 = $1[0];
      return new DecodedEvent(path, handler$1);
    } else {
      return new DispatchedEvent(path);
    }
  } else {
    return new DispatchedEvent(path);
  }
}
function handle(cache, path, name2, event3) {
  let _pipe = decode2(cache, path, name2, event3);
  return ((_capture) => {
    return dispatch(cache, _capture);
  })(_pipe);
}

// build/dev/javascript/lustre/lustre/runtime/server/runtime.mjs
class ClientDispatchedMessage extends CustomType {
  constructor(message) {
    super();
    this.message = message;
  }
}
var Message$isClientDispatchedMessage = (value2) => value2 instanceof ClientDispatchedMessage;
class ClientRegisteredCallback extends CustomType {
  constructor(callback) {
    super();
    this.callback = callback;
  }
}
var Message$isClientRegisteredCallback = (value2) => value2 instanceof ClientRegisteredCallback;
class ClientDeregisteredCallback extends CustomType {
  constructor(callback) {
    super();
    this.callback = callback;
  }
}
var Message$isClientDeregisteredCallback = (value2) => value2 instanceof ClientDeregisteredCallback;
class EffectDispatchedMessage extends CustomType {
  constructor(message) {
    super();
    this.message = message;
  }
}
var Message$EffectDispatchedMessage = (message) => new EffectDispatchedMessage(message);
var Message$isEffectDispatchedMessage = (value2) => value2 instanceof EffectDispatchedMessage;
class EffectEmitEvent extends CustomType {
  constructor(name2, data2) {
    super();
    this.name = name2;
    this.data = data2;
  }
}
var Message$EffectEmitEvent = (name2, data2) => new EffectEmitEvent(name2, data2);
var Message$isEffectEmitEvent = (value2) => value2 instanceof EffectEmitEvent;
class EffectProvidedValue extends CustomType {
  constructor(key, value2) {
    super();
    this.key = key;
    this.value = value2;
  }
}
var Message$EffectProvidedValue = (key, value2) => new EffectProvidedValue(key, value2);
var Message$isEffectProvidedValue = (value2) => value2 instanceof EffectProvidedValue;
class SystemRequestedShutdown extends CustomType {
}
var Message$isSystemRequestedShutdown = (value2) => value2 instanceof SystemRequestedShutdown;

// build/dev/javascript/lustre/lustre/internals/equals.ffi.mjs
var isEqual2 = (a, b) => {
  if (a === b) {
    return true;
  }
  if (a == null || b == null) {
    return false;
  }
  const type = typeof a;
  if (type !== typeof b) {
    return false;
  }
  if (type !== "object") {
    return false;
  }
  const ctor = a.constructor;
  if (ctor !== b.constructor) {
    return false;
  }
  if (Array.isArray(a)) {
    return areArraysEqual(a, b);
  }
  return areObjectsEqual(a, b);
};
var areArraysEqual = (a, b) => {
  let index4 = a.length;
  if (index4 !== b.length) {
    return false;
  }
  while (index4--) {
    if (!isEqual2(a[index4], b[index4])) {
      return false;
    }
  }
  return true;
};
var areObjectsEqual = (a, b) => {
  const properties = Object.keys(a);
  let index4 = properties.length;
  if (Object.keys(b).length !== index4) {
    return false;
  }
  while (index4--) {
    const property3 = properties[index4];
    if (!Object.hasOwn(b, property3)) {
      return false;
    }
    if (!isEqual2(a[property3], b[property3])) {
      return false;
    }
  }
  return true;
};

// build/dev/javascript/lustre/lustre/vdom/diff.mjs
class Diff extends CustomType {
  constructor(patch, cache) {
    super();
    this.patch = patch;
    this.cache = cache;
  }
}
class PartialDiff extends CustomType {
  constructor(patch, cache, events2) {
    super();
    this.patch = patch;
    this.cache = cache;
    this.events = events2;
  }
}

class AttributeChange extends CustomType {
  constructor(added, removed, events2) {
    super();
    this.added = added;
    this.removed = removed;
    this.events = events2;
  }
}
function is_controlled(cache, namespace, tag, path) {
  if (tag === "input" && namespace === "") {
    return has_dispatched_events(cache, path);
  } else if (tag === "select" && namespace === "") {
    return has_dispatched_events(cache, path);
  } else if (tag === "textarea" && namespace === "") {
    return has_dispatched_events(cache, path);
  } else {
    return false;
  }
}
function diff_attributes(loop$controlled, loop$path, loop$events, loop$old, loop$new, loop$added, loop$removed) {
  while (true) {
    let controlled = loop$controlled;
    let path = loop$path;
    let events2 = loop$events;
    let old = loop$old;
    let new$5 = loop$new;
    let added = loop$added;
    let removed = loop$removed;
    if (old instanceof Empty) {
      if (new$5 instanceof Empty) {
        return new AttributeChange(added, removed, events2);
      } else {
        let $ = new$5.head;
        if ($ instanceof Event2) {
          let next = $;
          let new$1 = new$5.tail;
          let name2 = $.name;
          let handler = $.handler;
          let events$1 = add_event(events2, path, name2, handler);
          let added$1 = prepend(next, added);
          loop$controlled = controlled;
          loop$path = path;
          loop$events = events$1;
          loop$old = old;
          loop$new = new$1;
          loop$added = added$1;
          loop$removed = removed;
        } else {
          let next = $;
          let new$1 = new$5.tail;
          let added$1 = prepend(next, added);
          loop$controlled = controlled;
          loop$path = path;
          loop$events = events2;
          loop$old = old;
          loop$new = new$1;
          loop$added = added$1;
          loop$removed = removed;
        }
      }
    } else if (new$5 instanceof Empty) {
      let $ = old.head;
      if ($ instanceof Event2) {
        let prev = $;
        let old$1 = old.tail;
        let name2 = $.name;
        let events$1 = remove_event(events2, path, name2);
        let removed$1 = prepend(prev, removed);
        loop$controlled = controlled;
        loop$path = path;
        loop$events = events$1;
        loop$old = old$1;
        loop$new = new$5;
        loop$added = added;
        loop$removed = removed$1;
      } else {
        let prev = $;
        let old$1 = old.tail;
        let removed$1 = prepend(prev, removed);
        loop$controlled = controlled;
        loop$path = path;
        loop$events = events2;
        loop$old = old$1;
        loop$new = new$5;
        loop$added = added;
        loop$removed = removed$1;
      }
    } else {
      let prev = old.head;
      let remaining_old = old.tail;
      let next = new$5.head;
      let remaining_new = new$5.tail;
      let $ = compare3(prev, next);
      if ($ instanceof Lt) {
        if (prev instanceof Event2) {
          let name2 = prev.name;
          loop$controlled = controlled;
          loop$path = path;
          loop$events = remove_event(events2, path, name2);
          loop$old = remaining_old;
          loop$new = new$5;
          loop$added = added;
          loop$removed = prepend(prev, removed);
        } else {
          loop$controlled = controlled;
          loop$path = path;
          loop$events = events2;
          loop$old = remaining_old;
          loop$new = new$5;
          loop$added = added;
          loop$removed = prepend(prev, removed);
        }
      } else if ($ instanceof Eq) {
        if (prev instanceof Attribute) {
          if (next instanceof Attribute) {
            let _block;
            let $1 = next.name;
            if ($1 === "value") {
              _block = controlled || prev.value !== next.value;
            } else if ($1 === "checked") {
              _block = controlled || prev.value !== next.value;
            } else if ($1 === "selected") {
              _block = controlled || prev.value !== next.value;
            } else {
              _block = prev.value !== next.value;
            }
            let has_changes = _block;
            let _block$1;
            if (has_changes) {
              _block$1 = prepend(next, added);
            } else {
              _block$1 = added;
            }
            let added$1 = _block$1;
            loop$controlled = controlled;
            loop$path = path;
            loop$events = events2;
            loop$old = remaining_old;
            loop$new = remaining_new;
            loop$added = added$1;
            loop$removed = removed;
          } else if (next instanceof Event2) {
            let name2 = next.name;
            let handler = next.handler;
            loop$controlled = controlled;
            loop$path = path;
            loop$events = add_event(events2, path, name2, handler);
            loop$old = remaining_old;
            loop$new = remaining_new;
            loop$added = prepend(next, added);
            loop$removed = prepend(prev, removed);
          } else {
            loop$controlled = controlled;
            loop$path = path;
            loop$events = events2;
            loop$old = remaining_old;
            loop$new = remaining_new;
            loop$added = prepend(next, added);
            loop$removed = prepend(prev, removed);
          }
        } else if (prev instanceof Property) {
          if (next instanceof Property) {
            let _block;
            let $1 = next.name;
            if ($1 === "scrollLeft") {
              _block = true;
            } else if ($1 === "scrollRight") {
              _block = true;
            } else if ($1 === "value") {
              _block = controlled || !isEqual2(prev.value, next.value);
            } else if ($1 === "checked") {
              _block = controlled || !isEqual2(prev.value, next.value);
            } else if ($1 === "selected") {
              _block = controlled || !isEqual2(prev.value, next.value);
            } else {
              _block = !isEqual2(prev.value, next.value);
            }
            let has_changes = _block;
            let _block$1;
            if (has_changes) {
              _block$1 = prepend(next, added);
            } else {
              _block$1 = added;
            }
            let added$1 = _block$1;
            loop$controlled = controlled;
            loop$path = path;
            loop$events = events2;
            loop$old = remaining_old;
            loop$new = remaining_new;
            loop$added = added$1;
            loop$removed = removed;
          } else if (next instanceof Event2) {
            let name2 = next.name;
            let handler = next.handler;
            loop$controlled = controlled;
            loop$path = path;
            loop$events = add_event(events2, path, name2, handler);
            loop$old = remaining_old;
            loop$new = remaining_new;
            loop$added = prepend(next, added);
            loop$removed = prepend(prev, removed);
          } else {
            loop$controlled = controlled;
            loop$path = path;
            loop$events = events2;
            loop$old = remaining_old;
            loop$new = remaining_new;
            loop$added = prepend(next, added);
            loop$removed = prepend(prev, removed);
          }
        } else if (next instanceof Event2) {
          let name2 = next.name;
          let handler = next.handler;
          let has_changes = prev.prevent_default.kind !== next.prevent_default.kind || prev.stop_propagation.kind !== next.stop_propagation.kind || prev.debounce !== next.debounce || prev.throttle !== next.throttle;
          let _block;
          if (has_changes) {
            _block = prepend(next, added);
          } else {
            _block = added;
          }
          let added$1 = _block;
          loop$controlled = controlled;
          loop$path = path;
          loop$events = add_event(events2, path, name2, handler);
          loop$old = remaining_old;
          loop$new = remaining_new;
          loop$added = added$1;
          loop$removed = removed;
        } else {
          let name2 = prev.name;
          loop$controlled = controlled;
          loop$path = path;
          loop$events = remove_event(events2, path, name2);
          loop$old = remaining_old;
          loop$new = remaining_new;
          loop$added = prepend(next, added);
          loop$removed = prepend(prev, removed);
        }
      } else if (next instanceof Event2) {
        let name2 = next.name;
        let handler = next.handler;
        loop$controlled = controlled;
        loop$path = path;
        loop$events = add_event(events2, path, name2, handler);
        loop$old = old;
        loop$new = remaining_new;
        loop$added = prepend(next, added);
        loop$removed = removed;
      } else {
        loop$controlled = controlled;
        loop$path = path;
        loop$events = events2;
        loop$old = old;
        loop$new = remaining_new;
        loop$added = prepend(next, added);
        loop$removed = removed;
      }
    }
  }
}
function do_diff(loop$old, loop$old_keyed, loop$new, loop$new_keyed, loop$moved, loop$moved_offset, loop$removed, loop$node_index, loop$patch_index, loop$changes, loop$children, loop$path, loop$cache, loop$events) {
  while (true) {
    let old = loop$old;
    let old_keyed = loop$old_keyed;
    let new$5 = loop$new;
    let new_keyed = loop$new_keyed;
    let moved = loop$moved;
    let moved_offset = loop$moved_offset;
    let removed = loop$removed;
    let node_index = loop$node_index;
    let patch_index = loop$patch_index;
    let changes = loop$changes;
    let children = loop$children;
    let path = loop$path;
    let cache = loop$cache;
    let events2 = loop$events;
    if (old instanceof Empty) {
      if (new$5 instanceof Empty) {
        let patch = new Patch(patch_index, removed, changes, children);
        return new PartialDiff(patch, cache, events2);
      } else {
        let $ = add_children(cache, events2, path, node_index, new$5);
        let cache$1;
        let events$1;
        cache$1 = $[0];
        events$1 = $[1];
        let insert4 = insert3(new$5, node_index - moved_offset);
        let changes$1 = prepend(insert4, changes);
        let patch = new Patch(patch_index, removed, changes$1, children);
        return new PartialDiff(patch, cache$1, events$1);
      }
    } else if (new$5 instanceof Empty) {
      let prev = old.head;
      let old$1 = old.tail;
      let _block;
      let $ = prev.key === "" || !has_key(moved, prev.key);
      if ($) {
        _block = removed + 1;
      } else {
        _block = removed;
      }
      let removed$1 = _block;
      let events$1 = remove_child(cache, events2, path, node_index, prev);
      loop$old = old$1;
      loop$old_keyed = old_keyed;
      loop$new = new$5;
      loop$new_keyed = new_keyed;
      loop$moved = moved;
      loop$moved_offset = moved_offset;
      loop$removed = removed$1;
      loop$node_index = node_index;
      loop$patch_index = patch_index;
      loop$changes = changes;
      loop$children = children;
      loop$path = path;
      loop$cache = cache;
      loop$events = events$1;
    } else {
      let prev = old.head;
      let next = new$5.head;
      if (prev.key !== next.key) {
        let old_remaining = old.tail;
        let new_remaining = new$5.tail;
        let next_did_exist = has_key(old_keyed, next.key);
        let prev_does_exist = has_key(new_keyed, prev.key);
        if (prev_does_exist) {
          if (next_did_exist) {
            let $ = has_key(moved, prev.key);
            if ($) {
              loop$old = old_remaining;
              loop$old_keyed = old_keyed;
              loop$new = new$5;
              loop$new_keyed = new_keyed;
              loop$moved = moved;
              loop$moved_offset = moved_offset - 1;
              loop$removed = removed;
              loop$node_index = node_index;
              loop$patch_index = patch_index;
              loop$changes = changes;
              loop$children = children;
              loop$path = path;
              loop$cache = cache;
              loop$events = events2;
            } else {
              let match = get2(old_keyed, next.key);
              let before = node_index - moved_offset;
              let changes$1 = prepend(move(next.key, before), changes);
              let moved$1 = insert2(moved, next.key, undefined);
              loop$old = prepend(match, old);
              loop$old_keyed = old_keyed;
              loop$new = new$5;
              loop$new_keyed = new_keyed;
              loop$moved = moved$1;
              loop$moved_offset = moved_offset + 1;
              loop$removed = removed;
              loop$node_index = node_index;
              loop$patch_index = patch_index;
              loop$changes = changes$1;
              loop$children = children;
              loop$path = path;
              loop$cache = cache;
              loop$events = events2;
            }
          } else {
            let before = node_index - moved_offset;
            let $ = add_child(cache, events2, path, node_index, next);
            let cache$1;
            let events$1;
            cache$1 = $[0];
            events$1 = $[1];
            let insert4 = insert3(toList([next]), before);
            let changes$1 = prepend(insert4, changes);
            loop$old = old;
            loop$old_keyed = old_keyed;
            loop$new = new_remaining;
            loop$new_keyed = new_keyed;
            loop$moved = moved;
            loop$moved_offset = moved_offset + 1;
            loop$removed = removed;
            loop$node_index = node_index + 1;
            loop$patch_index = patch_index;
            loop$changes = changes$1;
            loop$children = children;
            loop$path = path;
            loop$cache = cache$1;
            loop$events = events$1;
          }
        } else if (next_did_exist) {
          let index4 = node_index - moved_offset;
          let changes$1 = prepend(remove2(index4), changes);
          let events$1 = remove_child(cache, events2, path, node_index, prev);
          loop$old = old_remaining;
          loop$old_keyed = old_keyed;
          loop$new = new$5;
          loop$new_keyed = new_keyed;
          loop$moved = moved;
          loop$moved_offset = moved_offset - 1;
          loop$removed = removed;
          loop$node_index = node_index;
          loop$patch_index = patch_index;
          loop$changes = changes$1;
          loop$children = children;
          loop$path = path;
          loop$cache = cache;
          loop$events = events$1;
        } else {
          let change = replace2(node_index - moved_offset, next);
          let $ = replace_child(cache, events2, path, node_index, prev, next);
          let cache$1;
          let events$1;
          cache$1 = $[0];
          events$1 = $[1];
          loop$old = old_remaining;
          loop$old_keyed = old_keyed;
          loop$new = new_remaining;
          loop$new_keyed = new_keyed;
          loop$moved = moved;
          loop$moved_offset = moved_offset;
          loop$removed = removed;
          loop$node_index = node_index + 1;
          loop$patch_index = patch_index;
          loop$changes = prepend(change, changes);
          loop$children = children;
          loop$path = path;
          loop$cache = cache$1;
          loop$events = events$1;
        }
      } else {
        let $ = old.head;
        if ($ instanceof Fragment) {
          let $1 = new$5.head;
          if ($1 instanceof Fragment) {
            let prev2 = $;
            let old$1 = old.tail;
            let next2 = $1;
            let new$1 = new$5.tail;
            let $2 = do_diff(prev2.children, prev2.keyed_children, next2.children, next2.keyed_children, empty2(), 0, 0, 0, node_index, empty_list, empty_list, add2(path, node_index, next2.key), cache, events2);
            let patch;
            let cache$1;
            let events$1;
            patch = $2.patch;
            cache$1 = $2.cache;
            events$1 = $2.events;
            let _block;
            let $3 = patch.changes;
            if ($3 instanceof Empty) {
              let $4 = patch.children;
              if ($4 instanceof Empty) {
                let $5 = patch.removed;
                if ($5 === 0) {
                  _block = children;
                } else {
                  _block = prepend(patch, children);
                }
              } else {
                _block = prepend(patch, children);
              }
            } else {
              _block = prepend(patch, children);
            }
            let children$1 = _block;
            loop$old = old$1;
            loop$old_keyed = old_keyed;
            loop$new = new$1;
            loop$new_keyed = new_keyed;
            loop$moved = moved;
            loop$moved_offset = moved_offset;
            loop$removed = removed;
            loop$node_index = node_index + 1;
            loop$patch_index = patch_index;
            loop$changes = changes;
            loop$children = children$1;
            loop$path = path;
            loop$cache = cache$1;
            loop$events = events$1;
          } else {
            let prev2 = $;
            let old_remaining = old.tail;
            let next2 = $1;
            let new_remaining = new$5.tail;
            let change = replace2(node_index - moved_offset, next2);
            let $2 = replace_child(cache, events2, path, node_index, prev2, next2);
            let cache$1;
            let events$1;
            cache$1 = $2[0];
            events$1 = $2[1];
            loop$old = old_remaining;
            loop$old_keyed = old_keyed;
            loop$new = new_remaining;
            loop$new_keyed = new_keyed;
            loop$moved = moved;
            loop$moved_offset = moved_offset;
            loop$removed = removed;
            loop$node_index = node_index + 1;
            loop$patch_index = patch_index;
            loop$changes = prepend(change, changes);
            loop$children = children;
            loop$path = path;
            loop$cache = cache$1;
            loop$events = events$1;
          }
        } else if ($ instanceof Element) {
          let $1 = new$5.head;
          if ($1 instanceof Element) {
            let prev2 = $;
            let next2 = $1;
            if (prev2.namespace === next2.namespace && prev2.tag === next2.tag) {
              let old$1 = old.tail;
              let new$1 = new$5.tail;
              let child_path = add2(path, node_index, next2.key);
              let controlled = is_controlled(cache, next2.namespace, next2.tag, child_path);
              let $2 = diff_attributes(controlled, child_path, events2, prev2.attributes, next2.attributes, empty_list, empty_list);
              let added_attrs;
              let removed_attrs;
              let events$1;
              added_attrs = $2.added;
              removed_attrs = $2.removed;
              events$1 = $2.events;
              let _block;
              if (added_attrs instanceof Empty && removed_attrs instanceof Empty) {
                _block = empty_list;
              } else {
                _block = toList([update(added_attrs, removed_attrs)]);
              }
              let initial_child_changes = _block;
              let $3 = do_diff(prev2.children, prev2.keyed_children, next2.children, next2.keyed_children, empty2(), 0, 0, 0, node_index, initial_child_changes, empty_list, child_path, cache, events$1);
              let patch;
              let cache$1;
              let events$2;
              patch = $3.patch;
              cache$1 = $3.cache;
              events$2 = $3.events;
              let _block$1;
              let $4 = patch.changes;
              if ($4 instanceof Empty) {
                let $5 = patch.children;
                if ($5 instanceof Empty) {
                  let $6 = patch.removed;
                  if ($6 === 0) {
                    _block$1 = children;
                  } else {
                    _block$1 = prepend(patch, children);
                  }
                } else {
                  _block$1 = prepend(patch, children);
                }
              } else {
                _block$1 = prepend(patch, children);
              }
              let children$1 = _block$1;
              loop$old = old$1;
              loop$old_keyed = old_keyed;
              loop$new = new$1;
              loop$new_keyed = new_keyed;
              loop$moved = moved;
              loop$moved_offset = moved_offset;
              loop$removed = removed;
              loop$node_index = node_index + 1;
              loop$patch_index = patch_index;
              loop$changes = changes;
              loop$children = children$1;
              loop$path = path;
              loop$cache = cache$1;
              loop$events = events$2;
            } else {
              let prev3 = $;
              let old_remaining = old.tail;
              let next3 = $1;
              let new_remaining = new$5.tail;
              let change = replace2(node_index - moved_offset, next3);
              let $2 = replace_child(cache, events2, path, node_index, prev3, next3);
              let cache$1;
              let events$1;
              cache$1 = $2[0];
              events$1 = $2[1];
              loop$old = old_remaining;
              loop$old_keyed = old_keyed;
              loop$new = new_remaining;
              loop$new_keyed = new_keyed;
              loop$moved = moved;
              loop$moved_offset = moved_offset;
              loop$removed = removed;
              loop$node_index = node_index + 1;
              loop$patch_index = patch_index;
              loop$changes = prepend(change, changes);
              loop$children = children;
              loop$path = path;
              loop$cache = cache$1;
              loop$events = events$1;
            }
          } else {
            let prev2 = $;
            let old_remaining = old.tail;
            let next2 = $1;
            let new_remaining = new$5.tail;
            let change = replace2(node_index - moved_offset, next2);
            let $2 = replace_child(cache, events2, path, node_index, prev2, next2);
            let cache$1;
            let events$1;
            cache$1 = $2[0];
            events$1 = $2[1];
            loop$old = old_remaining;
            loop$old_keyed = old_keyed;
            loop$new = new_remaining;
            loop$new_keyed = new_keyed;
            loop$moved = moved;
            loop$moved_offset = moved_offset;
            loop$removed = removed;
            loop$node_index = node_index + 1;
            loop$patch_index = patch_index;
            loop$changes = prepend(change, changes);
            loop$children = children;
            loop$path = path;
            loop$cache = cache$1;
            loop$events = events$1;
          }
        } else if ($ instanceof Text) {
          let $1 = new$5.head;
          if ($1 instanceof Text) {
            let prev2 = $;
            let next2 = $1;
            if (prev2.content === next2.content) {
              let old$1 = old.tail;
              let new$1 = new$5.tail;
              loop$old = old$1;
              loop$old_keyed = old_keyed;
              loop$new = new$1;
              loop$new_keyed = new_keyed;
              loop$moved = moved;
              loop$moved_offset = moved_offset;
              loop$removed = removed;
              loop$node_index = node_index + 1;
              loop$patch_index = patch_index;
              loop$changes = changes;
              loop$children = children;
              loop$path = path;
              loop$cache = cache;
              loop$events = events2;
            } else {
              let old$1 = old.tail;
              let next3 = $1;
              let new$1 = new$5.tail;
              let child2 = new$3(node_index, 0, toList([replace_text(next3.content)]), empty_list);
              loop$old = old$1;
              loop$old_keyed = old_keyed;
              loop$new = new$1;
              loop$new_keyed = new_keyed;
              loop$moved = moved;
              loop$moved_offset = moved_offset;
              loop$removed = removed;
              loop$node_index = node_index + 1;
              loop$patch_index = patch_index;
              loop$changes = changes;
              loop$children = prepend(child2, children);
              loop$path = path;
              loop$cache = cache;
              loop$events = events2;
            }
          } else {
            let prev2 = $;
            let old_remaining = old.tail;
            let next2 = $1;
            let new_remaining = new$5.tail;
            let change = replace2(node_index - moved_offset, next2);
            let $2 = replace_child(cache, events2, path, node_index, prev2, next2);
            let cache$1;
            let events$1;
            cache$1 = $2[0];
            events$1 = $2[1];
            loop$old = old_remaining;
            loop$old_keyed = old_keyed;
            loop$new = new_remaining;
            loop$new_keyed = new_keyed;
            loop$moved = moved;
            loop$moved_offset = moved_offset;
            loop$removed = removed;
            loop$node_index = node_index + 1;
            loop$patch_index = patch_index;
            loop$changes = prepend(change, changes);
            loop$children = children;
            loop$path = path;
            loop$cache = cache$1;
            loop$events = events$1;
          }
        } else if ($ instanceof UnsafeInnerHtml) {
          let $1 = new$5.head;
          if ($1 instanceof UnsafeInnerHtml) {
            let prev2 = $;
            let old$1 = old.tail;
            let next2 = $1;
            let new$1 = new$5.tail;
            let child_path = add2(path, node_index, next2.key);
            let $2 = diff_attributes(false, child_path, events2, prev2.attributes, next2.attributes, empty_list, empty_list);
            let added_attrs;
            let removed_attrs;
            let events$1;
            added_attrs = $2.added;
            removed_attrs = $2.removed;
            events$1 = $2.events;
            let _block;
            if (added_attrs instanceof Empty && removed_attrs instanceof Empty) {
              _block = empty_list;
            } else {
              _block = toList([update(added_attrs, removed_attrs)]);
            }
            let child_changes = _block;
            let _block$1;
            let $3 = prev2.inner_html === next2.inner_html;
            if ($3) {
              _block$1 = child_changes;
            } else {
              _block$1 = prepend(replace_inner_html(next2.inner_html), child_changes);
            }
            let child_changes$1 = _block$1;
            let _block$2;
            if (child_changes$1 instanceof Empty) {
              _block$2 = children;
            } else {
              _block$2 = prepend(new$3(node_index, 0, child_changes$1, toList([])), children);
            }
            let children$1 = _block$2;
            loop$old = old$1;
            loop$old_keyed = old_keyed;
            loop$new = new$1;
            loop$new_keyed = new_keyed;
            loop$moved = moved;
            loop$moved_offset = moved_offset;
            loop$removed = removed;
            loop$node_index = node_index + 1;
            loop$patch_index = patch_index;
            loop$changes = changes;
            loop$children = children$1;
            loop$path = path;
            loop$cache = cache;
            loop$events = events$1;
          } else {
            let prev2 = $;
            let old_remaining = old.tail;
            let next2 = $1;
            let new_remaining = new$5.tail;
            let change = replace2(node_index - moved_offset, next2);
            let $2 = replace_child(cache, events2, path, node_index, prev2, next2);
            let cache$1;
            let events$1;
            cache$1 = $2[0];
            events$1 = $2[1];
            loop$old = old_remaining;
            loop$old_keyed = old_keyed;
            loop$new = new_remaining;
            loop$new_keyed = new_keyed;
            loop$moved = moved;
            loop$moved_offset = moved_offset;
            loop$removed = removed;
            loop$node_index = node_index + 1;
            loop$patch_index = patch_index;
            loop$changes = prepend(change, changes);
            loop$children = children;
            loop$path = path;
            loop$cache = cache$1;
            loop$events = events$1;
          }
        } else if ($ instanceof Map2) {
          let $1 = new$5.head;
          if ($1 instanceof Map2) {
            let prev2 = $;
            let old$1 = old.tail;
            let next2 = $1;
            let new$1 = new$5.tail;
            let child_path = add2(path, node_index, next2.key);
            let child_key = child(child_path);
            let $2 = do_diff(prepend(prev2.child, empty_list), empty2(), prepend(next2.child, empty_list), empty2(), empty2(), 0, 0, 0, node_index, empty_list, empty_list, subtree(child_path), cache, get_subtree(events2, child_key, prev2.mapper));
            let patch;
            let cache$1;
            let child_events;
            patch = $2.patch;
            cache$1 = $2.cache;
            child_events = $2.events;
            let events$1 = update_subtree(events2, child_key, next2.mapper, child_events);
            let _block;
            let $3 = patch.changes;
            if ($3 instanceof Empty) {
              let $4 = patch.children;
              if ($4 instanceof Empty) {
                let $5 = patch.removed;
                if ($5 === 0) {
                  _block = children;
                } else {
                  _block = prepend(patch, children);
                }
              } else {
                _block = prepend(patch, children);
              }
            } else {
              _block = prepend(patch, children);
            }
            let children$1 = _block;
            loop$old = old$1;
            loop$old_keyed = old_keyed;
            loop$new = new$1;
            loop$new_keyed = new_keyed;
            loop$moved = moved;
            loop$moved_offset = moved_offset;
            loop$removed = removed;
            loop$node_index = node_index + 1;
            loop$patch_index = patch_index;
            loop$changes = changes;
            loop$children = children$1;
            loop$path = path;
            loop$cache = cache$1;
            loop$events = events$1;
          } else {
            let prev2 = $;
            let old_remaining = old.tail;
            let next2 = $1;
            let new_remaining = new$5.tail;
            let change = replace2(node_index - moved_offset, next2);
            let $2 = replace_child(cache, events2, path, node_index, prev2, next2);
            let cache$1;
            let events$1;
            cache$1 = $2[0];
            events$1 = $2[1];
            loop$old = old_remaining;
            loop$old_keyed = old_keyed;
            loop$new = new_remaining;
            loop$new_keyed = new_keyed;
            loop$moved = moved;
            loop$moved_offset = moved_offset;
            loop$removed = removed;
            loop$node_index = node_index + 1;
            loop$patch_index = patch_index;
            loop$changes = prepend(change, changes);
            loop$children = children;
            loop$path = path;
            loop$cache = cache$1;
            loop$events = events$1;
          }
        } else {
          let $1 = new$5.head;
          if ($1 instanceof Memo) {
            let prev2 = $;
            let old$1 = old.tail;
            let next2 = $1;
            let new$1 = new$5.tail;
            let $2 = equal_lists(prev2.dependencies, next2.dependencies);
            if ($2) {
              let cache$1 = keep_memo(cache, prev2.view, next2.view);
              loop$old = old$1;
              loop$old_keyed = old_keyed;
              loop$new = new$1;
              loop$new_keyed = new_keyed;
              loop$moved = moved;
              loop$moved_offset = moved_offset;
              loop$removed = removed;
              loop$node_index = node_index + 1;
              loop$patch_index = patch_index;
              loop$changes = changes;
              loop$children = children;
              loop$path = path;
              loop$cache = cache$1;
              loop$events = events2;
            } else {
              let prev_node = get_old_memo(cache, prev2.view, prev2.view);
              let next_node = next2.view();
              let cache$1 = add_memo(cache, next2.view, next_node);
              loop$old = prepend(prev_node, old$1);
              loop$old_keyed = old_keyed;
              loop$new = prepend(next_node, new$1);
              loop$new_keyed = new_keyed;
              loop$moved = moved;
              loop$moved_offset = moved_offset;
              loop$removed = removed;
              loop$node_index = node_index;
              loop$patch_index = patch_index;
              loop$changes = changes;
              loop$children = children;
              loop$path = path;
              loop$cache = cache$1;
              loop$events = events2;
            }
          } else {
            let prev2 = $;
            let old_remaining = old.tail;
            let next2 = $1;
            let new_remaining = new$5.tail;
            let change = replace2(node_index - moved_offset, next2);
            let $2 = replace_child(cache, events2, path, node_index, prev2, next2);
            let cache$1;
            let events$1;
            cache$1 = $2[0];
            events$1 = $2[1];
            loop$old = old_remaining;
            loop$old_keyed = old_keyed;
            loop$new = new_remaining;
            loop$new_keyed = new_keyed;
            loop$moved = moved;
            loop$moved_offset = moved_offset;
            loop$removed = removed;
            loop$node_index = node_index + 1;
            loop$patch_index = patch_index;
            loop$changes = prepend(change, changes);
            loop$children = children;
            loop$path = path;
            loop$cache = cache$1;
            loop$events = events$1;
          }
        }
      }
    }
  }
}
function diff(cache, old, new$5) {
  let cache$1 = tick(cache);
  let $ = do_diff(prepend(old, empty_list), empty2(), prepend(new$5, empty_list), empty2(), empty2(), 0, 0, 0, 0, empty_list, empty_list, root, cache$1, events(cache$1));
  let patch;
  let cache$2;
  let events2;
  patch = $.patch;
  cache$2 = $.cache;
  events2 = $.events;
  return new Diff(patch, update_events(cache$2, events2));
}

// build/dev/javascript/lustre/lustre/internals/list.ffi.mjs
var toList2 = (arr) => arr.reduceRight((xs, x) => List$NonEmpty(x, xs), empty_list);
var iterate = (list4, callback) => {
  if (Array.isArray(list4)) {
    for (let i = 0;i < list4.length; i++) {
      callback(list4[i]);
    }
  } else if (list4) {
    for (list4;List$NonEmpty$rest(list4); list4 = List$NonEmpty$rest(list4)) {
      callback(List$NonEmpty$first(list4));
    }
  }
};
var append4 = (a, b) => {
  if (!List$NonEmpty$rest(a)) {
    return b;
  } else if (!List$NonEmpty$rest(b)) {
    return a;
  } else {
    return append(a, b);
  }
};

// build/dev/javascript/lustre/lustre/internals/constants.ffi.mjs
var document2 = () => globalThis?.document;
var NAMESPACE_HTML = "http://www.w3.org/1999/xhtml";
var ELEMENT_NODE = 1;
var TEXT_NODE = 3;
var COMMENT_NODE = 8;
var SUPPORTS_MOVE_BEFORE = !!globalThis.HTMLElement?.prototype?.moveBefore;

// build/dev/javascript/lustre/lustre/vdom/reconciler.ffi.mjs
var setTimeout = globalThis.setTimeout;
var clearTimeout = globalThis.clearTimeout;
var createElementNS = (ns, name2) => document2().createElementNS(ns, name2);
var createTextNode = (data2) => document2().createTextNode(data2);
var createComment = (data2) => document2().createComment(data2);
var createDocumentFragment = () => document2().createDocumentFragment();
var insertBefore = (parent, node, reference) => parent.insertBefore(node, reference);
var moveBefore = SUPPORTS_MOVE_BEFORE ? (parent, node, reference) => parent.moveBefore(node, reference) : insertBefore;
var removeChild = (parent, child2) => parent.removeChild(child2);
var getAttribute = (node, name2) => node.getAttribute(name2);
var setAttribute = (node, name2, value2) => node.setAttribute(name2, value2);
var removeAttribute = (node, name2) => node.removeAttribute(name2);
var addEventListener = (node, name2, handler, options) => node.addEventListener(name2, handler, options);
var removeEventListener = (node, name2, handler) => node.removeEventListener(name2, handler);
var setInnerHtml = (node, innerHtml) => node.innerHTML = innerHtml;
var setData = (node, data2) => node.data = data2;
var meta = Symbol("lustre");

class MetadataNode {
  constructor(kind, parent, node, key) {
    this.kind = kind;
    this.key = key;
    this.parent = parent;
    this.children = [];
    this.node = node;
    this.endNode = null;
    this.handlers = new Map;
    this.throttles = new Map;
    this.debouncers = new Map;
  }
  get isVirtual() {
    return this.kind === fragment_kind || this.kind === map_kind;
  }
  get parentNode() {
    return this.isVirtual ? this.node.parentNode : this.node;
  }
}
var insertMetadataChild = (kind, parent, node, index4, key) => {
  const child2 = new MetadataNode(kind, parent, node, key);
  node[meta] = child2;
  parent?.children.splice(index4, 0, child2);
  return child2;
};
var getPath = (node) => {
  let path = "";
  for (let current = node[meta];current.parent; current = current.parent) {
    const separator = current.parent && current.parent.kind === map_kind ? separator_subtree : separator_element;
    if (current.key) {
      path = `${separator}${current.key}${path}`;
    } else {
      const index4 = current.parent.children.indexOf(current);
      path = `${separator}${index4}${path}`;
    }
  }
  return path.slice(1);
};

class Reconciler {
  #root = null;
  #decodeEvent;
  #dispatch;
  #debug = false;
  constructor(root2, decodeEvent, dispatch2, { debug = false } = {}) {
    this.#root = root2;
    this.#decodeEvent = decodeEvent;
    this.#dispatch = dispatch2;
    this.#debug = debug;
  }
  mount(vdom) {
    insertMetadataChild(element_kind, null, this.#root, 0, null);
    this.#insertChild(this.#root, null, this.#root[meta], 0, vdom);
  }
  push(patch, memos2 = null) {
    this.#memos = memos2;
    this.#stack.push({ node: this.#root[meta], patch });
    this.#reconcile();
  }
  #memos;
  #stack = [];
  #reconcile() {
    const stack = this.#stack;
    while (stack.length) {
      const { node, patch } = stack.pop();
      const { children: childNodes } = node;
      const { changes, removed, children: childPatches } = patch;
      iterate(changes, (change) => this.#patch(node, change));
      if (removed) {
        this.#removeChildren(node, childNodes.length - removed, removed);
      }
      iterate(childPatches, (childPatch) => {
        const child2 = childNodes[childPatch.index | 0];
        this.#stack.push({ node: child2, patch: childPatch });
      });
    }
  }
  #patch(node, change) {
    switch (change.kind) {
      case replace_text_kind:
        this.#replaceText(node, change);
        break;
      case replace_inner_html_kind:
        this.#replaceInnerHtml(node, change);
        break;
      case update_kind:
        this.#update(node, change);
        break;
      case move_kind:
        this.#move(node, change);
        break;
      case remove_kind:
        this.#remove(node, change);
        break;
      case replace_kind:
        this.#replace(node, change);
        break;
      case insert_kind:
        this.#insert(node, change);
        break;
    }
  }
  #insert(parent, { children, before }) {
    const fragment3 = createDocumentFragment();
    const beforeEl = this.#getReference(parent, before);
    this.#insertChildren(fragment3, null, parent, before | 0, children);
    insertBefore(parent.parentNode, fragment3, beforeEl);
  }
  #replace(parent, { index: index4, with: child2 }) {
    this.#removeChildren(parent, index4 | 0, 1);
    const beforeEl = this.#getReference(parent, index4);
    this.#insertChild(parent.parentNode, beforeEl, parent, index4 | 0, child2);
  }
  #getReference(node, index4) {
    index4 = index4 | 0;
    const { children } = node;
    const childCount = children.length;
    if (index4 < childCount)
      return children[index4].node;
    if (node.endNode)
      return node.endNode;
    if (!node.isVirtual || !childCount)
      return null;
    let lastChild = children[childCount - 1];
    while (lastChild.isVirtual && lastChild.children.length) {
      if (lastChild.endNode)
        return lastChild.endNode.nextSibling;
      lastChild = lastChild.children[lastChild.children.length - 1];
    }
    return lastChild.node.nextSibling;
  }
  #move(parent, { key, before }) {
    before = before | 0;
    const { children, parentNode } = parent;
    const beforeEl = children[before].node;
    let prev = children[before];
    for (let i = before + 1;i < children.length; ++i) {
      const next = children[i];
      children[i] = prev;
      prev = next;
      if (next.key === key) {
        children[before] = next;
        break;
      }
    }
    this.#moveChild(parentNode, prev, beforeEl);
  }
  #moveChildren(domParent, children, beforeEl) {
    for (let i = 0;i < children.length; ++i) {
      this.#moveChild(domParent, children[i], beforeEl);
    }
  }
  #moveChild(domParent, child2, beforeEl) {
    moveBefore(domParent, child2.node, beforeEl);
    if (child2.isVirtual) {
      this.#moveChildren(domParent, child2.children, beforeEl);
    }
    if (child2.endNode) {
      moveBefore(domParent, child2.endNode, beforeEl);
    }
  }
  #remove(parent, { index: index4 }) {
    this.#removeChildren(parent, index4, 1);
  }
  #removeChildren(parent, index4, count) {
    const { children, parentNode } = parent;
    const deleted = children.splice(index4, count);
    for (let i = 0;i < deleted.length; ++i) {
      const child2 = deleted[i];
      const { node, endNode, isVirtual, children: nestedChildren } = child2;
      removeChild(parentNode, node);
      if (endNode) {
        removeChild(parentNode, endNode);
      }
      this.#removeDebouncers(child2);
      if (isVirtual) {
        deleted.push(...nestedChildren);
      }
    }
  }
  #removeDebouncers(node) {
    const { debouncers, children } = node;
    for (const { timeout } of debouncers.values()) {
      if (timeout) {
        clearTimeout(timeout);
      }
    }
    debouncers.clear();
    iterate(children, (child2) => this.#removeDebouncers(child2));
  }
  #update({ node, handlers, throttles, debouncers }, { added, removed }) {
    iterate(removed, ({ name: name2 }) => {
      if (handlers.delete(name2)) {
        removeEventListener(node, name2, handleEvent);
        this.#updateDebounceThrottle(throttles, name2, 0);
        this.#updateDebounceThrottle(debouncers, name2, 0);
      } else {
        removeAttribute(node, name2);
        SYNCED_ATTRIBUTES[name2]?.removed?.(node, name2);
      }
    });
    iterate(added, (attribute3) => this.#createAttribute(node, attribute3));
  }
  #replaceText({ node }, { content }) {
    setData(node, content ?? "");
  }
  #replaceInnerHtml({ node }, { inner_html }) {
    setInnerHtml(node, inner_html ?? "");
  }
  #insertChildren(domParent, beforeEl, metaParent, index4, children) {
    iterate(children, (child2) => this.#insertChild(domParent, beforeEl, metaParent, index4++, child2));
  }
  #insertChild(domParent, beforeEl, metaParent, index4, vnode) {
    switch (vnode.kind) {
      case element_kind: {
        const node = this.#createElement(metaParent, index4, vnode);
        this.#insertChildren(node, null, node[meta], 0, vnode.children);
        insertBefore(domParent, node, beforeEl);
        break;
      }
      case text_kind: {
        const node = this.#createTextNode(metaParent, index4, vnode);
        insertBefore(domParent, node, beforeEl);
        break;
      }
      case fragment_kind: {
        const marker = "lustre:fragment";
        const head = this.#createHead(marker, metaParent, index4, vnode);
        insertBefore(domParent, head, beforeEl);
        this.#insertChildren(domParent, beforeEl, head[meta], 0, vnode.children);
        if (this.#debug) {
          head[meta].endNode = createComment(` /${marker} `);
          insertBefore(domParent, head[meta].endNode, beforeEl);
        }
        break;
      }
      case unsafe_inner_html_kind: {
        const node = this.#createElement(metaParent, index4, vnode);
        this.#replaceInnerHtml({ node }, vnode);
        insertBefore(domParent, node, beforeEl);
        break;
      }
      case map_kind: {
        const head = this.#createHead("lustre:map", metaParent, index4, vnode);
        insertBefore(domParent, head, beforeEl);
        this.#insertChild(domParent, beforeEl, head[meta], 0, vnode.child);
        break;
      }
      case memo_kind: {
        const child2 = this.#memos?.get(vnode.view) ?? vnode.view();
        this.#insertChild(domParent, beforeEl, metaParent, index4, child2);
        break;
      }
    }
  }
  #createElement(parent, index4, { kind, key, tag, namespace, attributes }) {
    const node = createElementNS(namespace || NAMESPACE_HTML, tag);
    insertMetadataChild(kind, parent, node, index4, key);
    if (this.#debug && key) {
      setAttribute(node, "data-lustre-key", key);
    }
    iterate(attributes, (attribute3) => this.#createAttribute(node, attribute3));
    return node;
  }
  #createTextNode(parent, index4, { kind, key, content }) {
    const node = createTextNode(content ?? "");
    insertMetadataChild(kind, parent, node, index4, key);
    return node;
  }
  #createHead(marker, parent, index4, { kind, key }) {
    const node = this.#debug ? createComment(markerComment(marker, key)) : createTextNode("");
    insertMetadataChild(kind, parent, node, index4, key);
    return node;
  }
  #createAttribute(node, attribute3) {
    const { debouncers, handlers, throttles } = node[meta];
    const {
      kind,
      name: name2,
      value: value2,
      prevent_default: prevent,
      debounce: debounceDelay,
      throttle: throttleDelay
    } = attribute3;
    switch (kind) {
      case attribute_kind: {
        const valueOrDefault = value2 ?? "";
        if (name2 === "virtual:defaultValue") {
          node.defaultValue = valueOrDefault;
          return;
        } else if (name2 === "virtual:defaultChecked") {
          node.defaultChecked = true;
          return;
        } else if (name2 === "virtual:defaultSelected") {
          node.defaultSelected = true;
          return;
        }
        if (valueOrDefault !== getAttribute(node, name2)) {
          setAttribute(node, name2, valueOrDefault);
        }
        SYNCED_ATTRIBUTES[name2]?.added?.(node, valueOrDefault);
        break;
      }
      case property_kind:
        node[name2] = value2;
        break;
      case event_kind: {
        if (handlers.has(name2)) {
          removeEventListener(node, name2, handleEvent);
        }
        const passive = prevent.kind === never_kind;
        addEventListener(node, name2, handleEvent, { passive });
        this.#updateDebounceThrottle(throttles, name2, throttleDelay);
        this.#updateDebounceThrottle(debouncers, name2, debounceDelay);
        handlers.set(name2, (event3) => this.#handleEvent(attribute3, event3));
        break;
      }
    }
  }
  #updateDebounceThrottle(map6, name2, delay) {
    const debounceOrThrottle = map6.get(name2);
    if (delay > 0) {
      if (debounceOrThrottle) {
        debounceOrThrottle.delay = delay;
      } else {
        map6.set(name2, { delay });
      }
    } else if (debounceOrThrottle) {
      const { timeout } = debounceOrThrottle;
      if (timeout) {
        clearTimeout(timeout);
      }
      map6.delete(name2);
    }
  }
  #handleEvent(attribute3, event3) {
    const { currentTarget, type } = event3;
    const { debouncers, throttles } = currentTarget[meta];
    const path = getPath(currentTarget);
    const {
      prevent_default: prevent,
      stop_propagation: stop,
      include
    } = attribute3;
    if (prevent.kind === always_kind)
      event3.preventDefault();
    if (stop.kind === always_kind)
      event3.stopPropagation();
    if (type === "submit") {
      event3.detail ??= {};
      event3.detail.formData = [
        ...new FormData(event3.target, event3.submitter).entries()
      ];
    }
    const data2 = this.#decodeEvent(event3, path, type, include);
    const throttle = throttles.get(type);
    if (throttle) {
      const now = Date.now();
      const last = throttle.last || 0;
      if (now > last + throttle.delay) {
        throttle.last = now;
        throttle.lastEvent = event3;
        this.#dispatch(event3, data2);
      }
    }
    const debounce = debouncers.get(type);
    if (debounce) {
      clearTimeout(debounce.timeout);
      debounce.timeout = setTimeout(() => {
        if (event3 === throttles.get(type)?.lastEvent)
          return;
        this.#dispatch(event3, data2);
      }, debounce.delay);
    }
    if (!throttle && !debounce) {
      this.#dispatch(event3, data2);
    }
  }
}
var markerComment = (marker, key) => {
  if (key) {
    return ` ${marker} key="${escape2(key)}" `;
  } else {
    return ` ${marker} `;
  }
};
var handleEvent = (event3) => {
  const { currentTarget, type } = event3;
  const handler = currentTarget[meta].handlers.get(type);
  handler(event3);
};
var syncedBooleanAttribute = (name2) => {
  return {
    added(node) {
      node[name2] = true;
    },
    removed(node) {
      node[name2] = false;
    }
  };
};
var syncedAttribute = (name2) => {
  return {
    added(node, value2) {
      node[name2] = value2;
    }
  };
};
var SYNCED_ATTRIBUTES = {
  checked: syncedBooleanAttribute("checked"),
  selected: syncedBooleanAttribute("selected"),
  value: syncedAttribute("value"),
  autofocus: {
    added(node) {
      queueMicrotask(() => {
        node.focus?.();
      });
    }
  },
  autoplay: {
    added(node) {
      try {
        node.play?.();
      } catch (e) {
        console.error(e);
      }
    }
  }
};

// build/dev/javascript/lustre/lustre/element/keyed.mjs
function do_extract_keyed_children(loop$key_children_pairs, loop$keyed_children, loop$children) {
  while (true) {
    let key_children_pairs = loop$key_children_pairs;
    let keyed_children = loop$keyed_children;
    let children = loop$children;
    if (key_children_pairs instanceof Empty) {
      return [keyed_children, reverse(children)];
    } else {
      let rest = key_children_pairs.tail;
      let key = key_children_pairs.head[0];
      let element$1 = key_children_pairs.head[1];
      let keyed_element = to_keyed(key, element$1);
      let _block;
      if (key === "") {
        _block = keyed_children;
      } else {
        _block = insert2(keyed_children, key, keyed_element);
      }
      let keyed_children$1 = _block;
      let children$1 = prepend(keyed_element, children);
      loop$key_children_pairs = rest;
      loop$keyed_children = keyed_children$1;
      loop$children = children$1;
    }
  }
}
function extract_keyed_children(children) {
  return do_extract_keyed_children(children, empty2(), empty_list);
}
function element3(tag, attributes, children) {
  let $ = extract_keyed_children(children);
  let keyed_children;
  let children$1;
  keyed_children = $[0];
  children$1 = $[1];
  return element("", "", tag, attributes, children$1, keyed_children, false, is_void_html_element(tag, ""));
}
function namespaced2(namespace, tag, attributes, children) {
  let $ = extract_keyed_children(children);
  let keyed_children;
  let children$1;
  keyed_children = $[0];
  children$1 = $[1];
  return element("", namespace, tag, attributes, children$1, keyed_children, false, is_void_html_element(tag, namespace));
}
function fragment3(children) {
  let $ = extract_keyed_children(children);
  let keyed_children;
  let children$1;
  keyed_children = $[0];
  children$1 = $[1];
  return fragment("", children$1, keyed_children);
}

// build/dev/javascript/lustre/lustre/vdom/virtualise.ffi.mjs
var virtualise = (root2) => {
  const rootMeta = insertMetadataChild(element_kind, null, root2, 0, null);
  for (let child2 = root2.firstChild;child2; child2 = child2.nextSibling) {
    const result = virtualiseChild(rootMeta, root2, child2, 0);
    if (result)
      return result.vnode;
  }
  const placeholder2 = document2().createTextNode("");
  insertMetadataChild(text_kind, rootMeta, placeholder2, 0, null);
  root2.insertBefore(placeholder2, root2.firstChild);
  return none2();
};
var virtualiseChild = (meta2, domParent, child2, index4) => {
  if (child2.nodeType === COMMENT_NODE) {
    const data2 = child2.data.trim();
    if (data2.startsWith("lustre:fragment")) {
      return virtualiseFragment(meta2, domParent, child2, index4);
    }
    if (data2.startsWith("lustre:map")) {
      return virtualiseMap(meta2, domParent, child2, index4);
    }
    if (data2.startsWith("lustre:memo")) {
      return virtualiseMemo(meta2, domParent, child2, index4);
    }
    return null;
  }
  if (child2.nodeType === ELEMENT_NODE) {
    return virtualiseElement(meta2, child2, index4);
  }
  if (child2.nodeType === TEXT_NODE) {
    return virtualiseText(meta2, child2, index4);
  }
  return null;
};
var virtualiseElement = (metaParent, node, index4) => {
  const key = node.getAttribute("data-lustre-key") ?? "";
  if (key) {
    node.removeAttribute("data-lustre-key");
  }
  const meta2 = insertMetadataChild(element_kind, metaParent, node, index4, key);
  const tag = node.localName;
  const namespace = node.namespaceURI;
  const isHtmlElement = !namespace || namespace === NAMESPACE_HTML;
  if (isHtmlElement && INPUT_ELEMENTS.includes(tag)) {
    virtualiseInputEvents(tag, node);
  }
  const attributes = virtualiseAttributes(node);
  const children = [];
  for (let childNode = node.firstChild;childNode; ) {
    const child2 = virtualiseChild(meta2, node, childNode, children.length);
    if (child2) {
      children.push([child2.key, child2.vnode]);
      childNode = child2.next;
    } else {
      childNode = childNode.nextSibling;
    }
  }
  const vnode = isHtmlElement ? element3(tag, attributes, toList3(children)) : namespaced2(namespace, tag, attributes, toList3(children));
  return childResult(key, vnode, node.nextSibling);
};
var virtualiseText = (meta2, node, index4) => {
  insertMetadataChild(text_kind, meta2, node, index4, null);
  return childResult("", text2(node.data), node.nextSibling);
};
var virtualiseFragment = (metaParent, domParent, node, index4) => {
  const key = parseKey(node.data);
  const meta2 = insertMetadataChild(fragment_kind, metaParent, node, index4, key);
  const children = [];
  node = node.nextSibling;
  while (node && (node.nodeType !== COMMENT_NODE || node.data.trim() !== "/lustre:fragment")) {
    const child2 = virtualiseChild(meta2, domParent, node, children.length);
    if (child2) {
      children.push([child2.key, child2.vnode]);
      node = child2.next;
    } else {
      node = node.nextSibling;
    }
  }
  meta2.endNode = node;
  const vnode = fragment3(toList3(children));
  return childResult(key, vnode, node?.nextSibling);
};
var virtualiseMap = (metaParent, domParent, node, index4) => {
  const key = parseKey(node.data);
  const meta2 = insertMetadataChild(map_kind, metaParent, node, index4, key);
  const child2 = virtualiseNextChild(meta2, domParent, node, 0);
  if (!child2)
    return null;
  const vnode = map5(child2.vnode, (x) => x);
  return childResult(key, vnode, child2.next);
};
var virtualiseMemo = (meta2, domParent, node, index4) => {
  const key = parseKey(node.data);
  const child2 = virtualiseNextChild(meta2, domParent, node, index4);
  if (!child2)
    return null;
  domParent.removeChild(node);
  const vnode = memo2(toList3([ref({})]), () => child2.vnode);
  return childResult(key, vnode, child2.next);
};
var virtualiseNextChild = (meta2, domParent, node, index4) => {
  while (true) {
    node = node.nextSibling;
    if (!node)
      return null;
    const child2 = virtualiseChild(meta2, domParent, node, index4);
    if (child2)
      return child2;
  }
};
var childResult = (key, vnode, next) => {
  return { key, vnode, next };
};
var virtualiseAttributes = (node) => {
  const attributes = [];
  for (let i = 0;i < node.attributes.length; i++) {
    const attr = node.attributes[i];
    if (attr.name !== "xmlns") {
      attributes.push(attribute2(attr.localName, attr.value));
    }
  }
  return toList3(attributes);
};
var INPUT_ELEMENTS = ["input", "select", "textarea"];
var virtualiseInputEvents = (tag, node) => {
  const value2 = node.value;
  const checked2 = node.checked;
  if (tag === "input" && node.type === "checkbox" && !checked2)
    return;
  if (tag === "input" && node.type === "radio" && !checked2)
    return;
  if (node.type !== "checkbox" && node.type !== "radio" && !value2)
    return;
  queueMicrotask(() => {
    node.value = value2;
    node.checked = checked2;
    node.dispatchEvent(new Event("input", { bubbles: true }));
    node.dispatchEvent(new Event("change", { bubbles: true }));
    if (document2().activeElement !== node) {
      node.dispatchEvent(new Event("blur", { bubbles: true }));
    }
  });
};
var parseKey = (data2) => {
  const keyMatch = data2.match(/key="([^"]*)"/);
  if (!keyMatch)
    return "";
  return unescapeKey(keyMatch[1]);
};
var unescapeKey = (key) => {
  return key.replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&quot;/g, '"').replace(/&amp;/g, "&").replace(/&#39;/g, "'");
};
var toList3 = (arr) => arr.reduceRight((xs, x) => List$NonEmpty(x, xs), empty_list);

// build/dev/javascript/lustre/lustre/runtime/client/runtime.ffi.mjs
var is_browser = () => !!document2();
class Runtime {
  constructor(root2, [model, effects], view, update2, options) {
    this.root = root2;
    this.#model = model;
    this.#view = view;
    this.#update = update2;
    this.root.addEventListener("context-request", (event3) => {
      if (!(event3.context && event3.callback))
        return;
      if (!this.#contexts.has(event3.context))
        return;
      event3.stopImmediatePropagation();
      const context = this.#contexts.get(event3.context);
      if (event3.subscribe) {
        const unsubscribe = () => {
          context.subscribers = context.subscribers.filter((subscriber) => subscriber !== event3.callback);
        };
        context.subscribers.push([event3.callback, unsubscribe]);
        event3.callback(context.value, unsubscribe);
      } else {
        event3.callback(context.value);
      }
    });
    const decodeEvent = (event3, path, name2) => decode2(this.#cache, path, name2, event3);
    const dispatch2 = (event3, data2) => {
      const [cache, result] = dispatch(this.#cache, data2);
      this.#cache = cache;
      if (Result$isOk(result)) {
        const handler = Result$Ok$0(result);
        if (handler.stop_propagation)
          event3.stopPropagation();
        if (handler.prevent_default)
          event3.preventDefault();
        this.dispatch(handler.message, false);
      }
    };
    this.#reconciler = new Reconciler(this.root, decodeEvent, dispatch2, options);
    this.#vdom = virtualise(this.root);
    this.#cache = new$4();
    this.#handleEffects(effects);
    this.#render();
  }
  root = null;
  dispatch(msg, shouldFlush = false) {
    if (this.#shouldQueue) {
      this.#queue.push(msg);
    } else {
      const [model, effects] = this.#update(this.#model, msg);
      this.#model = model;
      this.#tick(effects, shouldFlush);
    }
  }
  emit(event3, data2) {
    const target = this.root.host ?? this.root;
    target.dispatchEvent(new CustomEvent(event3, {
      detail: data2,
      bubbles: true,
      composed: true
    }));
  }
  provide(key, value2) {
    if (!this.#contexts.has(key)) {
      this.#contexts.set(key, { value: value2, subscribers: [] });
    } else {
      const context = this.#contexts.get(key);
      if (isEqual2(context.value, value2)) {
        return;
      }
      context.value = value2;
      for (let i = context.subscribers.length - 1;i >= 0; i--) {
        const [subscriber, unsubscribe] = context.subscribers[i];
        if (!subscriber) {
          context.subscribers.splice(i, 1);
          continue;
        }
        subscriber(value2, unsubscribe);
      }
    }
  }
  #model;
  #view;
  #update;
  #vdom;
  #cache;
  #reconciler;
  #contexts = new Map;
  #shouldQueue = false;
  #queue = [];
  #beforePaint = empty_list;
  #afterPaint = empty_list;
  #renderTimer = null;
  #actions = {
    dispatch: (msg) => this.dispatch(msg),
    emit: (event3, data2) => this.emit(event3, data2),
    select: () => {},
    root: () => this.root,
    provide: (key, value2) => this.provide(key, value2)
  };
  #tick(effects, shouldFlush = false) {
    this.#handleEffects(effects);
    if (!this.#renderTimer) {
      if (shouldFlush) {
        this.#renderTimer = "sync";
        queueMicrotask(() => this.#render());
      } else {
        this.#renderTimer = window.requestAnimationFrame(() => this.#render());
      }
    }
  }
  #handleEffects(effects) {
    this.#shouldQueue = true;
    while (true) {
      iterate(effects.synchronous, (effect) => effect(this.#actions));
      this.#beforePaint = append4(this.#beforePaint, effects.before_paint);
      this.#afterPaint = append4(this.#afterPaint, effects.after_paint);
      if (!this.#queue.length)
        break;
      const msg = this.#queue.shift();
      [this.#model, effects] = this.#update(this.#model, msg);
    }
    this.#shouldQueue = false;
  }
  #render() {
    this.#renderTimer = null;
    const next = this.#view(this.#model);
    const { patch, cache } = diff(this.#cache, this.#vdom, next);
    this.#cache = cache;
    this.#vdom = next;
    this.#reconciler.push(patch, memos(cache));
    if (List$isNonEmpty(this.#beforePaint)) {
      const effects = makeEffect(this.#beforePaint);
      this.#beforePaint = empty_list;
      queueMicrotask(() => {
        this.#tick(effects, true);
      });
    }
    if (List$isNonEmpty(this.#afterPaint)) {
      const effects = makeEffect(this.#afterPaint);
      this.#afterPaint = empty_list;
      window.requestAnimationFrame(() => this.#tick(effects, true));
    }
  }
}
function makeEffect(synchronous) {
  return {
    synchronous,
    after_paint: empty_list,
    before_paint: empty_list
  };
}
var copiedStyleSheets = new WeakMap;

// build/dev/javascript/lustre/lustre/component.mjs
class Config2 extends CustomType {
  constructor(open_shadow_root, adopt_styles, delegates_focus, attributes, properties, contexts, is_form_associated, on_form_autofill, on_form_reset, on_form_restore) {
    super();
    this.open_shadow_root = open_shadow_root;
    this.adopt_styles = adopt_styles;
    this.delegates_focus = delegates_focus;
    this.attributes = attributes;
    this.properties = properties;
    this.contexts = contexts;
    this.is_form_associated = is_form_associated;
    this.on_form_autofill = on_form_autofill;
    this.on_form_reset = on_form_reset;
    this.on_form_restore = on_form_restore;
  }
}
function new$5(options) {
  let init = new Config2(true, true, false, empty_list, empty_list, empty_list, false, new None, new None, new None);
  return fold2(options, init, (config, option) => {
    return option.apply(config);
  });
}

// build/dev/javascript/lustre/lustre/runtime/client/spa.ffi.mjs
class Spa {
  #runtime;
  constructor(root2, [init, effects], update2, view) {
    this.#runtime = new Runtime(root2, [init, effects], view, update2);
  }
  send(message) {
    if (Message$isEffectDispatchedMessage(message)) {
      this.dispatch(message.message, false);
    } else if (Message$isEffectEmitEvent(message)) {
      this.emit(message.name, message.data);
    } else if (Message$isSystemRequestedShutdown(message)) {}
  }
  dispatch(msg) {
    this.#runtime.dispatch(msg);
  }
  emit(event3, data2) {
    this.#runtime.emit(event3, data2);
  }
}
var start = ({ init, update: update2, view }, selector, flags) => {
  if (!is_browser())
    return Result$Error(Error$NotABrowser());
  const root2 = selector instanceof HTMLElement ? selector : document2().querySelector(selector);
  if (!root2)
    return Result$Error(Error$ElementNotFound(selector));
  return Result$Ok(new Spa(root2, init(flags), update2, view));
};

// build/dev/javascript/lustre/lustre/runtime/server/runtime.ffi.mjs
class Runtime2 {
  #model;
  #update;
  #view;
  #config;
  #vdom;
  #cache;
  #providers = make();
  #callbacks = /* @__PURE__ */ new Set;
  constructor([model, effects], update2, view, config) {
    this.#model = model;
    this.#update = update2;
    this.#view = view;
    this.#config = config;
    this.#vdom = this.#view(this.#model);
    this.#cache = from_node(this.#vdom);
    this.#handle_effect(effects);
  }
  send(msg) {
    if (Message$isClientDispatchedMessage(msg)) {
      const { message } = msg;
      const next = this.#handle_client_message(message);
      const diff2 = diff(this.#cache, this.#vdom, next);
      this.#vdom = next;
      this.#cache = diff2.cache;
      this.broadcast(reconcile(diff2.patch, memos(diff2.cache)));
    } else if (Message$isClientRegisteredCallback(msg)) {
      const { callback } = msg;
      this.#callbacks.add(callback);
      callback(mount(this.#config.open_shadow_root, this.#config.adopt_styles, keys(this.#config.attributes), keys(this.#config.properties), keys(this.#config.contexts), this.#providers, this.#vdom, memos(this.#cache)));
    } else if (Message$isClientDeregisteredCallback(msg)) {
      const { callback } = msg;
      this.#callbacks.delete(callback);
    } else if (Message$isEffectDispatchedMessage(msg)) {
      const { message } = msg;
      const [model, effect] = this.#update(this.#model, message);
      const next = this.#view(model);
      const diff2 = diff(this.#cache, this.#vdom, next);
      this.#handle_effect(effect);
      this.#model = model;
      this.#vdom = next;
      this.#cache = diff2.cache;
      this.broadcast(reconcile(diff2.patch, memos(diff2.cache)));
    } else if (Message$isEffectEmitEvent(msg)) {
      const { name: name2, data: data2 } = msg;
      this.broadcast(emit(name2, data2));
    } else if (Message$isEffectProvidedValue(msg)) {
      const { key, value: value2 } = msg;
      const existing = get(this.#providers, key);
      if (Result$isOk(existing) && isEqual2(Result$Ok$0(existing), value2)) {
        return;
      }
      this.#providers = insert(this.#providers, key, value2);
      this.broadcast(provide(key, value2));
    } else if (Message$isSystemRequestedShutdown(msg)) {
      this.#model = null;
      this.#update = null;
      this.#view = null;
      this.#config = null;
      this.#vdom = null;
      this.#cache = null;
      this.#providers = null;
      this.#callbacks.clear();
    }
  }
  broadcast(msg) {
    for (const callback of this.#callbacks) {
      callback(msg);
    }
  }
  #handle_client_message(msg) {
    if (ServerMessage$isBatch(msg)) {
      const { messages } = msg;
      let model = this.#model;
      let effect = none();
      for (let list4 = messages;List$NonEmpty$rest(list4); list4 = List$NonEmpty$rest(list4)) {
        const result = this.#handle_client_message(List$NonEmpty$first(list4));
        if (Result$isOk(result)) {
          model = Result$Ok$0(result)[0];
          effect = batch(toList2([effect, Result$Ok$0(result)[1]]));
          break;
        }
      }
      this.#handle_effect(effect);
      this.#model = model;
      return this.#view(model);
    } else if (ServerMessage$isAttributeChanged(msg)) {
      const { name: name2, value: value2 } = msg;
      const result = this.#handle_attribute_change(name2, value2);
      if (!Result$isOk(result)) {
        return this.#vdom;
      }
      return this.#dispatch(Result$Ok$0(result));
    } else if (ServerMessage$isPropertyChanged(msg)) {
      const { name: name2, value: value2 } = msg;
      const result = this.#handle_properties_change(name2, value2);
      if (!Result$isOk(result)) {
        return this.#vdom;
      }
      return this.#dispatch(Result$Ok$0(result));
    } else if (ServerMessage$isEventFired(msg)) {
      const { path, name: name2, event: event3 } = msg;
      const [cache, result] = handle(this.#cache, path, name2, event3);
      this.#cache = cache;
      if (!Result$isOk(result)) {
        return this.#vdom;
      }
      const { message } = Result$Ok$0(result);
      return this.#dispatch(message);
    } else if (ServerMessage$isContextProvided(msg)) {
      const { key, value: value2 } = msg;
      let result = get(this.#config.contexts, key);
      if (!Result$isOk(result)) {
        return this.#vdom;
      }
      result = run(value2, Result$Ok$0(result));
      if (!Result$isOk(result)) {
        return this.#vdom;
      }
      return this.#dispatch(Result$Ok$0(result));
    }
  }
  #dispatch(msg) {
    const [model, effects] = this.#update(this.#model, msg);
    this.#handle_effect(effects);
    this.#model = model;
    return this.#view(this.#model);
  }
  #handle_attribute_change(name2, value2) {
    const result = get(this.#config.attributes, name2);
    if (!Result$isOk(result)) {
      return result;
    }
    return Result$Ok$0(result)(value2);
  }
  #handle_properties_change(name2, value2) {
    const result = get(this.#config.properties, name2);
    if (!Result$isOk(result)) {
      return result;
    }
    return Result$Ok$0(result)(value2);
  }
  #handle_effect(effect) {
    const dispatch2 = (message) => this.send(Message$EffectDispatchedMessage(message));
    const emit2 = (name2, data2) => this.send(Message$EffectEmitEvent(name2, data2));
    const select = () => {
      return;
    };
    const internals = () => {
      return;
    };
    const provide2 = (key, value2) => this.send(Message$EffectProvidedValue(key, value2));
    globalThis.queueMicrotask(() => {
      perform(effect, dispatch2, emit2, select, internals, provide2);
    });
  }
}

// build/dev/javascript/lustre/lustre.mjs
class App extends CustomType {
  constructor(name2, init, update2, view, config) {
    super();
    this.name = name2;
    this.init = init;
    this.update = update2;
    this.view = view;
    this.config = config;
  }
}
class ElementNotFound extends CustomType {
  constructor(selector) {
    super();
    this.selector = selector;
  }
}
var Error$ElementNotFound = (selector) => new ElementNotFound(selector);
class NotABrowser extends CustomType {
}
var Error$NotABrowser = () => new NotABrowser;
function application(init, update2, view) {
  return new App(new None, init, update2, view, new$5(empty_list));
}
function simple(init, update2, view) {
  let init$1 = (start_args) => {
    return [init(start_args), none()];
  };
  let update$1 = (model, msg) => {
    return [update2(model, msg), none()];
  };
  return application(init$1, update$1, view);
}
function start4(app, selector, start_args) {
  return guard(!is_browser(), new Error(new NotABrowser), () => {
    return start(app, selector, start_args);
  });
}

// build/dev/javascript/lustre/lustre/event.mjs
function on(name2, handler) {
  return event(name2, map3(handler, (msg) => {
    return new Handler(false, false, msg);
  }), empty_list, never, never, 0, 0);
}
function on_click(msg) {
  return on("click", success(msg));
}
// build/dev/javascript/example_08_complete/components/common/empty_state.mjs
function render(icon, title, description, action_label, on_action) {
  return div(toList([
    class$("flex flex-col items-center justify-center py-12 px-4 text-center")
  ]), toList([
    div(toList([class$("text-6xl mb-4")]), toList([text2(icon)])),
    h3(toList([class$("text-lg font-medium text-gray-900 mb-2")]), toList([text2(title)])),
    p(toList([class$("text-gray-500 mb-6 max-w-sm")]), toList([text2(description)])),
    element2("sl-button", toList([
      attribute2("variant", "primary"),
      on_click(on_action())
    ]), toList([text2(action_label)]))
  ]));
}

// build/dev/javascript/example_08_complete/model.mjs
class Task extends CustomType {
  constructor(id, title, description, status, priority, due_date, project_id, subtasks, created_at, updated_at) {
    super();
    this.id = id;
    this.title = title;
    this.description = description;
    this.status = status;
    this.priority = priority;
    this.due_date = due_date;
    this.project_id = project_id;
    this.subtasks = subtasks;
    this.created_at = created_at;
    this.updated_at = updated_at;
  }
}
class Subtask extends CustomType {
  constructor(id, text4, completed) {
    super();
    this.id = id;
    this.text = text4;
    this.completed = completed;
  }
}
class Todo extends CustomType {
}
class InProgress extends CustomType {
}
class Done extends CustomType {
}
class High extends CustomType {
}
class Medium extends CustomType {
}
class Low extends CustomType {
}
class NoPriority extends CustomType {
}
class Project extends CustomType {
  constructor(id, name2, color, task_count) {
    super();
    this.id = id;
    this.name = name2;
    this.color = color;
    this.task_count = task_count;
  }
}
class ListView extends CustomType {
}
class KanbanView extends CustomType {
}
class All extends CustomType {
}
class ByProject extends CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
class Today extends CustomType {
}
class Overdue extends CustomType {
}
class SortByCreated extends CustomType {
}
class SortByDueDate extends CustomType {
}
class SortByPriority extends CustomType {
}
class SortByTitle extends CustomType {
}
class Success extends CustomType {
}
class Error3 extends CustomType {
}
class Warning extends CustomType {
}
class Info extends CustomType {
}
class NoDialog extends CustomType {
}
class AddTaskDialog extends CustomType {
}
class EditTaskDialog extends CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
class DeleteConfirmDialog extends CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
class ExportDialog extends CustomType {
}
class FormState extends CustomType {
  constructor(title, description, priority, due_date, project_id) {
    super();
    this.title = title;
    this.description = description;
    this.priority = priority;
    this.due_date = due_date;
    this.project_id = project_id;
  }
}
class Model extends CustomType {
  constructor(tasks, projects, current_view, current_filter, sort_by, search_query, sidebar_open, selected_task_id, editing_task, dialog_open, toast, form, dark_mode, new_subtask_text, editing_subtask_id, editing_subtask_text) {
    super();
    this.tasks = tasks;
    this.projects = projects;
    this.current_view = current_view;
    this.current_filter = current_filter;
    this.sort_by = sort_by;
    this.search_query = search_query;
    this.sidebar_open = sidebar_open;
    this.selected_task_id = selected_task_id;
    this.editing_task = editing_task;
    this.dialog_open = dialog_open;
    this.toast = toast;
    this.form = form;
    this.dark_mode = dark_mode;
    this.new_subtask_text = new_subtask_text;
    this.editing_subtask_id = editing_subtask_id;
    this.editing_subtask_text = editing_subtask_text;
  }
}
function empty_form() {
  return new FormState("", "", new NoPriority, new None, new None);
}
function sample_tasks() {
  return toList([
    new Task("1", "Set up project structure", "Create the initial folder structure and configuration files", new Done, new High, new Some("2024-01-15"), new Some("proj-1"), toList([
      new Subtask("1-1", "Create directories", true),
      new Subtask("1-2", "Add configuration", true)
    ]), "2024-01-10", "2024-01-15"),
    new Task("2", "Implement core features", "Build the main functionality of the application", new InProgress, new High, new Some("2024-01-20"), new Some("proj-1"), toList([
      new Subtask("2-1", "Task CRUD operations", true),
      new Subtask("2-2", "Filtering and search", false),
      new Subtask("2-3", "Persistence", false)
    ]), "2024-01-12", "2024-01-18"),
    new Task("3", "Write documentation", "Create comprehensive documentation for the project", new Todo, new Medium, new Some("2024-01-25"), new Some("proj-1"), toList([]), "2024-01-14", "2024-01-14"),
    new Task("4", "Review pull requests", "Review and merge pending PRs", new Todo, new Low, new None, new Some("proj-2"), toList([]), "2024-01-16", "2024-01-16"),
    new Task("5", "Fix login bug", "Users are unable to log in on mobile devices", new InProgress, new High, new Some("2024-01-18"), new Some("proj-2"), toList([
      new Subtask("5-1", "Reproduce issue", true),
      new Subtask("5-2", "Identify root cause", true),
      new Subtask("5-3", "Implement fix", false),
      new Subtask("5-4", "Test on devices", false)
    ]), "2024-01-17", "2024-01-18")
  ]);
}
function sample_projects() {
  return toList([
    new Project("proj-1", "Task Manager", "#3b82f6", 3),
    new Project("proj-2", "Bug Fixes", "#ef4444", 2)
  ]);
}
function initial_model() {
  return new Model(sample_tasks(), sample_projects(), new ListView, new All, new SortByCreated, "", false, new None, new None, new NoDialog, new None, empty_form(), false, "", new None, "");
}
function priority_to_string(priority) {
  if (priority instanceof High) {
    return "high";
  } else if (priority instanceof Medium) {
    return "medium";
  } else if (priority instanceof Low) {
    return "low";
  } else {
    return "none";
  }
}
function priority_from_string(s) {
  if (s === "high") {
    return new High;
  } else if (s === "medium") {
    return new Medium;
  } else if (s === "low") {
    return new Low;
  } else {
    return new NoPriority;
  }
}
function count_completed(loop$subtasks, loop$acc) {
  while (true) {
    let subtasks = loop$subtasks;
    let acc = loop$acc;
    if (subtasks instanceof Empty) {
      return acc;
    } else {
      let first = subtasks.head;
      let rest = subtasks.tail;
      let $ = first.completed;
      if ($) {
        loop$subtasks = rest;
        loop$acc = acc + 1;
      } else {
        loop$subtasks = rest;
        loop$acc = acc;
      }
    }
  }
}
function completed_subtasks(task) {
  return count_completed(task.subtasks, 0);
}

// build/dev/javascript/example_08_complete/components/common/toast.mjs
function render2(message, toast_type, is_visible, on_dismiss) {
  if (is_visible) {
    return div(toList([class$("fixed bottom-4 right-4 z-50 animate-slide-up")]), toList([
      (() => {
        if (toast_type instanceof Success) {
          return div(toList([
            class$("bg-green-100 text-green-800 rounded-lg px-4 py-3 flex items-center gap-3 shadow-lg")
          ]), toList([
            span(toList([]), toList([text2("Success")])),
            span(toList([]), toList([text2(message)])),
            button(toList([
              class$("ml-4 text-green-600 hover:text-green-800"),
              on_click(on_dismiss())
            ]), toList([text2("x")]))
          ]));
        } else if (toast_type instanceof Error3) {
          return div(toList([
            class$("bg-red-100 text-red-800 rounded-lg px-4 py-3 flex items-center gap-3 shadow-lg")
          ]), toList([
            span(toList([]), toList([text2("Error")])),
            span(toList([]), toList([text2(message)])),
            button(toList([
              class$("ml-4 text-red-600 hover:text-red-800"),
              on_click(on_dismiss())
            ]), toList([text2("x")]))
          ]));
        } else if (toast_type instanceof Warning) {
          return div(toList([
            class$("bg-yellow-100 text-yellow-800 rounded-lg px-4 py-3 flex items-center gap-3 shadow-lg")
          ]), toList([
            span(toList([]), toList([text2("Warning")])),
            span(toList([]), toList([text2(message)])),
            button(toList([
              class$("ml-4 text-yellow-600 hover:text-yellow-800"),
              on_click(on_dismiss())
            ]), toList([text2("x")]))
          ]));
        } else {
          return div(toList([
            class$("bg-blue-100 text-blue-800 rounded-lg px-4 py-3 flex items-center gap-3 shadow-lg")
          ]), toList([
            span(toList([]), toList([text2("Info")])),
            span(toList([]), toList([text2(message)])),
            button(toList([
              class$("ml-4 text-blue-600 hover:text-blue-800"),
              on_click(on_dismiss())
            ]), toList([text2("x")]))
          ]));
        }
      })()
    ]));
  } else {
    return none2();
  }
}

// build/dev/javascript/example_08_complete/components/dialogs/confirm_dialog.mjs
function render3(is_open, title, message, confirm_label, on_confirm, on_cancel, on_close_decoder) {
  if (is_open) {
    return element2("sl-dialog", toList([
      attribute2("label", title),
      attribute2("open", ""),
      on("sl-hide", on_close_decoder)
    ]), toList([
      p(toList([class$("text-gray-600")]), toList([text2(message)])),
      div(toList([
        attribute2("slot", "footer"),
        class$("flex gap-2 justify-end")
      ]), toList([
        element2("sl-button", toList([
          attribute2("variant", "default"),
          on_click(on_cancel())
        ]), toList([text2("Cancel")])),
        element2("sl-button", toList([
          attribute2("variant", "danger"),
          on_click(on_confirm())
        ]), toList([text2(confirm_label)]))
      ]))
    ]));
  } else {
    return span(toList([]), toList([]));
  }
}

// build/dev/javascript/example_08_complete/components/dialogs/export_dialog.mjs
function render4(is_open, on_export, on_import, on_clear, on_close, on_close_decoder) {
  if (is_open) {
    return element2("sl-dialog", toList([
      attribute2("label", "Import / Export"),
      attribute2("open", ""),
      on("sl-hide", on_close_decoder)
    ]), toList([
      div(toList([class$("space-y-4")]), toList([
        div(toList([class$("p-4 bg-gray-50 rounded-lg")]), toList([
          h3(toList([class$("font-medium text-gray-900 mb-2")]), toList([text2("Export Tasks")])),
          p(toList([class$("text-sm text-gray-600 mb-3")]), toList([text2("Download all your tasks as a JSON file.")])),
          element2("sl-button", toList([
            attribute2("variant", "primary"),
            on_click(on_export())
          ]), toList([text2("Export to JSON")]))
        ])),
        div(toList([class$("p-4 bg-gray-50 rounded-lg")]), toList([
          h3(toList([class$("font-medium text-gray-900 mb-2")]), toList([text2("Import Tasks")])),
          p(toList([class$("text-sm text-gray-600 mb-3")]), toList([text2("Upload a JSON file to import tasks.")])),
          element2("sl-button", toList([
            attribute2("variant", "default"),
            on_click(on_import())
          ]), toList([text2("Import from JSON")]))
        ])),
        div(toList([class$("p-4 bg-red-50 rounded-lg")]), toList([
          h3(toList([class$("font-medium text-red-900 mb-2")]), toList([text2("Clear All Data")])),
          p(toList([class$("text-sm text-red-600 mb-3")]), toList([
            text2("Permanently delete all tasks and projects. This action cannot be undone.")
          ])),
          element2("sl-button", toList([
            attribute2("variant", "danger"),
            on_click(on_clear())
          ]), toList([text2("Clear All Data")]))
        ]))
      ])),
      div(toList([attribute2("slot", "footer")]), toList([
        element2("sl-button", toList([
          attribute2("variant", "default"),
          on_click(on_close())
        ]), toList([text2("Close")]))
      ]))
    ]));
  } else {
    return span(toList([]), toList([]));
  }
}

// build/dev/javascript/example_08_complete/components/filters/filter_bar.mjs
function render5(current_filter, on_filter_change, on_sort_change) {
  return div(toList([class$("flex flex-wrap items-center gap-3 mb-4")]), toList([
    div(toList([class$("flex items-center gap-2")]), toList([
      span(toList([
        class$("text-sm text-gray-500 dark:text-gray-400")
      ]), toList([text2("Filter:")])),
      div(toList([class$("flex gap-1")]), toList([
        button(toList([
          class$("px-3 py-1 text-sm rounded-md"),
          on_click(on_filter_change(new All))
        ]), toList([
          (() => {
            let $ = current_filter instanceof All;
            if ($) {
              return span(toList([
                class$("bg-blue-100 dark:bg-blue-900 text-blue-700 dark:text-blue-200 px-3 py-1 rounded-md")
              ]), toList([text2("All")]));
            } else {
              return span(toList([
                class$("bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600 dark:text-gray-200 px-3 py-1 rounded-md")
              ]), toList([text2("All")]));
            }
          })()
        ])),
        button(toList([
          class$("px-3 py-1 text-sm rounded-md"),
          on_click(on_filter_change(new Today))
        ]), toList([
          (() => {
            let $ = current_filter instanceof Today;
            if ($) {
              return span(toList([
                class$("bg-blue-100 dark:bg-blue-900 text-blue-700 dark:text-blue-200 px-3 py-1 rounded-md")
              ]), toList([text2("Today")]));
            } else {
              return span(toList([
                class$("bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600 dark:text-gray-200 px-3 py-1 rounded-md")
              ]), toList([text2("Today")]));
            }
          })()
        ])),
        button(toList([
          class$("px-3 py-1 text-sm rounded-md"),
          on_click(on_filter_change(new Overdue))
        ]), toList([
          (() => {
            let $ = current_filter instanceof Overdue;
            if ($) {
              return span(toList([
                class$("bg-blue-100 dark:bg-blue-900 text-blue-700 dark:text-blue-200 px-3 py-1 rounded-md")
              ]), toList([text2("Overdue")]));
            } else {
              return span(toList([
                class$("bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600 dark:text-gray-200 px-3 py-1 rounded-md")
              ]), toList([text2("Overdue")]));
            }
          })()
        ]))
      ]))
    ])),
    div(toList([class$("flex items-center gap-2")]), toList([
      span(toList([
        class$("text-sm text-gray-500 dark:text-gray-400")
      ]), toList([text2("Sort:")])),
      element2("sl-select", toList([
        value("created"),
        on("sl-change", on_sort_change)
      ]), toList([
        element2("sl-option", toList([value("created")]), toList([text2("Created")])),
        element2("sl-option", toList([value("due_date")]), toList([text2("Due Date")])),
        element2("sl-option", toList([value("priority")]), toList([text2("Priority")])),
        element2("sl-option", toList([value("title")]), toList([text2("Title")]))
      ]))
    ]))
  ]));
}

// build/dev/javascript/example_08_complete/components/layout/header.mjs
function render6(current_view, search_query, dark_mode, on_toggle_sidebar, on_view_change, on_search_change, on_toggle_dark_mode, on_add_task) {
  return header(toList([
    class$("bg-white dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700 px-4 py-3")
  ]), toList([
    div(toList([class$("flex items-center justify-between")]), toList([
      div(toList([class$("flex items-center gap-4")]), toList([
        button(toList([
          class$("lg:hidden p-2 rounded-md hover:bg-gray-100 dark:hover:bg-gray-700 dark:text-gray-200"),
          on_click(on_toggle_sidebar())
        ]), toList([
          span(toList([class$("text-xl")]), toList([text2("Menu")]))
        ])),
        div(toList([class$("hidden sm:flex items-center gap-2")]), toList([
          button(toList([
            class$("px-3 py-1.5 text-sm rounded-md dark:text-gray-200"),
            on_click(on_view_change(new ListView))
          ]), toList([
            (() => {
              let $ = current_view instanceof ListView;
              if ($) {
                return span(toList([
                  class$("bg-gray-200 dark:bg-gray-600 px-3 py-1.5 rounded-md")
                ]), toList([text2("List")]));
              } else {
                return span(toList([
                  class$("hover:bg-gray-100 dark:hover:bg-gray-700 px-3 py-1.5 rounded-md")
                ]), toList([text2("List")]));
              }
            })()
          ])),
          button(toList([
            class$("px-3 py-1.5 text-sm rounded-md dark:text-gray-200"),
            on_click(on_view_change(new KanbanView))
          ]), toList([
            (() => {
              let $ = current_view instanceof KanbanView;
              if ($) {
                return span(toList([
                  class$("bg-gray-200 dark:bg-gray-600 px-3 py-1.5 rounded-md")
                ]), toList([text2("Board")]));
              } else {
                return span(toList([
                  class$("hover:bg-gray-100 dark:hover:bg-gray-700 px-3 py-1.5 rounded-md")
                ]), toList([text2("Board")]));
              }
            })()
          ]))
        ]))
      ])),
      div(toList([class$("flex items-center gap-3")]), toList([
        element2("sl-input", toList([
          class$("w-48 sm:w-64"),
          placeholder("Search tasks..."),
          value(search_query),
          on("sl-input", on_search_change)
        ]), toList([])),
        element2("sl-tooltip", toList([
          attribute2("content", (() => {
            if (dark_mode) {
              return "Switch to light mode";
            } else {
              return "Switch to dark mode";
            }
          })())
        ]), toList([
          element2("sl-icon-button", toList([
            name((() => {
              if (dark_mode) {
                return "sun";
              } else {
                return "moon";
              }
            })()),
            attribute2("label", "Toggle dark mode"),
            on_click(on_toggle_dark_mode()),
            class$("text-xl")
          ]), toList([]))
        ])),
        element2("sl-button", toList([
          attribute2("variant", "primary"),
          on_click(on_add_task())
        ]), toList([span(toList([]), toList([text2("+ Add Task")]))]))
      ]))
    ]))
  ]));
}

// build/dev/javascript/example_08_complete/components/layout/mobile_nav.mjs
function render7(current_view, on_view_change, on_add_task) {
  return nav(toList([
    class$("bg-white dark:bg-gray-800 border-t border-gray-200 dark:border-gray-700 px-4 py-2 safe-area-pb")
  ]), toList([
    div(toList([class$("flex items-center justify-around")]), toList([
      button(toList([
        class$("flex flex-col items-center py-2 px-4"),
        on_click(on_view_change(new ListView))
      ]), toList([
        (() => {
          let $ = current_view instanceof ListView;
          if ($) {
            return fragment2(toList([
              span(toList([
                class$("text-blue-600 dark:text-blue-400 text-2xl")
              ]), toList([text2("List")])),
              span(toList([
                class$("text-xs text-blue-600 dark:text-blue-400 font-medium")
              ]), toList([text2("List")]))
            ]));
          } else {
            return fragment2(toList([
              span(toList([class$("text-gray-400 text-2xl")]), toList([text2("List")])),
              span(toList([class$("text-xs text-gray-400")]), toList([text2("List")]))
            ]));
          }
        })()
      ])),
      button(toList([
        class$("flex items-center justify-center w-14 h-14 -mt-6 bg-blue-600 dark:bg-blue-500 rounded-full shadow-lg text-white text-2xl"),
        on_click(on_add_task())
      ]), toList([text2(`
 +
 `)])),
      button(toList([
        class$("flex flex-col items-center py-2 px-4"),
        on_click(on_view_change(new KanbanView))
      ]), toList([
        (() => {
          let $ = current_view instanceof KanbanView;
          if ($) {
            return fragment2(toList([
              span(toList([
                class$("text-blue-600 dark:text-blue-400 text-2xl")
              ]), toList([text2("Board")])),
              span(toList([
                class$("text-xs text-blue-600 dark:text-blue-400 font-medium")
              ]), toList([text2("Board")]))
            ]));
          } else {
            return fragment2(toList([
              span(toList([class$("text-gray-400 text-2xl")]), toList([text2("Board")])),
              span(toList([class$("text-xs text-gray-400")]), toList([text2("Board")]))
            ]));
          }
        })()
      ]))
    ]))
  ]));
}

// build/dev/javascript/example_08_complete/components/layout/sidebar.mjs
function render8(projects, current_project, on_select_all, on_select_project, on_create_project) {
  return nav(toList([
    class$("h-full bg-white dark:bg-gray-800 border-r border-gray-200 dark:border-gray-700 flex flex-col")
  ]), toList([
    div(toList([
      class$("p-4 border-b border-gray-200 dark:border-gray-700")
    ]), toList([
      h1(toList([
        class$("text-xl font-bold text-gray-900 dark:text-white")
      ]), toList([text2("Task Manager")]))
    ])),
    div(toList([class$("flex-1 overflow-y-auto py-4")]), toList([
      div(toList([class$("px-4 mb-4")]), toList([
        h2(toList([
          class$("text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider mb-2")
        ]), toList([text2("Quick Filters")])),
        ul(toList([class$("space-y-1")]), toList([
          li(toList([]), toList([
            button(toList([
              class$("w-full flex items-center px-3 py-2 text-sm rounded-md hover:bg-gray-100 dark:hover:bg-gray-700 dark:text-gray-200"),
              on_click(on_select_all())
            ]), toList([
              span(toList([class$("mr-3")]), toList([text2("All Tasks")]))
            ]))
          ]))
        ]))
      ])),
      div(toList([class$("px-4")]), toList([
        div(toList([
          class$("flex items-center justify-between mb-2")
        ]), toList([
          h2(toList([
            class$("text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider")
          ]), toList([text2("Projects")])),
          button(toList([
            class$("text-gray-400 hover:text-gray-600 dark:hover:text-gray-200"),
            on_click(on_create_project())
          ]), toList([span(toList([]), toList([text2("+")]))]))
        ])),
        ul(toList([class$("space-y-1")]), toList([
          fragment3(index_map(projects, (project, idx) => {
            return [
              to_string(idx),
              li(toList([]), toList([
                button(toList([
                  class$("w-full flex items-center px-3 py-2 text-sm rounded-md hover:bg-gray-100 dark:hover:bg-gray-700"),
                  on_click(on_select_project(project.id))
                ]), toList([
                  (() => {
                    let $ = isEqual(current_project, new Some(project.id));
                    if ($) {
                      return span(toList([
                        class$("font-medium text-blue-600 dark:text-blue-400")
                      ]), toList([text2(project.name)]));
                    } else {
                      return span(toList([
                        class$("text-gray-700 dark:text-gray-300")
                      ]), toList([text2(project.name)]));
                    }
                  })(),
                  span(toList([
                    class$("ml-auto text-xs text-gray-400")
                  ]), toList([
                    text2(to_string(project.task_count))
                  ]))
                ]))
              ]))
            ];
          }))
        ]))
      ]))
    ]))
  ]));
}

// build/dev/javascript/example_08_complete/components/tasks/kanban_board.mjs
function render9(todo_tasks, in_progress_tasks, done_tasks, on_task_click) {
  return div(toList([class$("grid grid-cols-1 md:grid-cols-3 gap-4 lg:gap-6")]), toList([
    div(toList([
      class$("bg-gray-100 dark:bg-gray-800 rounded-lg p-4")
    ]), toList([
      h2(toList([
        class$("font-semibold text-gray-700 dark:text-gray-200 mb-4 flex items-center gap-2")
      ]), toList([
        span(toList([class$("w-3 h-3 rounded-full bg-gray-400")]), toList([])),
        text2(`
 Todo
 `),
        span(toList([
          class$("ml-auto text-sm font-normal text-gray-500 dark:text-gray-400")
        ]), toList([text2(to_string(length(todo_tasks)))]))
      ])),
      div(toList([class$("space-y-3")]), toList([
        fragment3(index_map(todo_tasks, (task, idx) => {
          return [
            to_string(idx),
            div(toList([
              class$("bg-white dark:bg-gray-700 p-3 rounded-lg shadow-sm cursor-pointer hover:shadow-md transition-shadow"),
              on_click(on_task_click(task.id))
            ]), toList([
              h3(toList([
                class$("font-medium text-gray-900 dark:text-white")
              ]), toList([text2(task.title)])),
              (() => {
                let $ = task.description !== "";
                if ($) {
                  return p(toList([
                    class$("text-sm text-gray-500 dark:text-gray-400 mt-1 line-clamp-2")
                  ]), toList([text2(task.description)]));
                } else {
                  return none2();
                }
              })()
            ]))
          ];
        }))
      ]))
    ])),
    div(toList([
      class$("bg-blue-50 dark:bg-blue-900/30 rounded-lg p-4")
    ]), toList([
      h2(toList([
        class$("font-semibold text-gray-700 dark:text-gray-200 mb-4 flex items-center gap-2")
      ]), toList([
        span(toList([class$("w-3 h-3 rounded-full bg-blue-500")]), toList([])),
        text2(`
 In Progress
 `),
        span(toList([
          class$("ml-auto text-sm font-normal text-gray-500 dark:text-gray-400")
        ]), toList([text2(to_string(length(in_progress_tasks)))]))
      ])),
      div(toList([class$("space-y-3")]), toList([
        fragment3(index_map(in_progress_tasks, (task, idx2) => {
          return [
            to_string(idx2),
            div(toList([
              class$("bg-white dark:bg-gray-700 p-3 rounded-lg shadow-sm cursor-pointer hover:shadow-md transition-shadow"),
              on_click(on_task_click(task.id))
            ]), toList([
              h3(toList([
                class$("font-medium text-gray-900 dark:text-white")
              ]), toList([text2(task.title)])),
              (() => {
                let $ = task.description !== "";
                if ($) {
                  return p(toList([
                    class$("text-sm text-gray-500 dark:text-gray-400 mt-1 line-clamp-2")
                  ]), toList([text2(task.description)]));
                } else {
                  return none2();
                }
              })()
            ]))
          ];
        }))
      ]))
    ])),
    div(toList([
      class$("bg-green-50 dark:bg-green-900/30 rounded-lg p-4")
    ]), toList([
      h2(toList([
        class$("font-semibold text-gray-700 dark:text-gray-200 mb-4 flex items-center gap-2")
      ]), toList([
        span(toList([class$("w-3 h-3 rounded-full bg-green-500")]), toList([])),
        text2(`
 Done
 `),
        span(toList([
          class$("ml-auto text-sm font-normal text-gray-500 dark:text-gray-400")
        ]), toList([text2(to_string(length(done_tasks)))]))
      ])),
      div(toList([class$("space-y-3")]), toList([
        fragment3(index_map(done_tasks, (task, idx3) => {
          return [
            to_string(idx3),
            div(toList([
              class$("bg-white dark:bg-gray-700 p-3 rounded-lg shadow-sm cursor-pointer hover:shadow-md transition-shadow"),
              on_click(on_task_click(task.id))
            ]), toList([
              h3(toList([
                class$("font-medium text-gray-900 dark:text-white line-through")
              ]), toList([text2(task.title)])),
              (() => {
                let $ = task.description !== "";
                if ($) {
                  return p(toList([
                    class$("text-sm text-gray-400 mt-1 line-clamp-2")
                  ]), toList([text2(task.description)]));
                } else {
                  return none2();
                }
              })()
            ]))
          ];
        }))
      ]))
    ]))
  ]));
}

// build/dev/javascript/example_08_complete/components/tasks/task_detail.mjs
function render10(task, new_subtask_text, editing_subtask_id, editing_subtask_text, on_edit, on_delete, on_toggle_status, on_toggle_subtask, on_subtask_input, on_add_subtask_keydown, on_add_subtask_click, on_delete_subtask, on_start_edit_subtask, on_edit_subtask_input, on_save_edit_subtask, on_cancel_edit_subtask, on_close) {
  return div(toList([
    class$("bg-white dark:bg-gray-800 rounded-lg shadow-lg p-6")
  ]), toList([
    div(toList([class$("flex items-start justify-between mb-4")]), toList([
      div(toList([]), toList([
        h2(toList([
          class$("text-xl font-semibold text-gray-900 dark:text-white")
        ]), toList([text2(task.title)])),
        div(toList([class$("mt-1 flex items-center gap-2")]), toList([
          (() => {
            let $ = task.status;
            if ($ instanceof Todo) {
              return span(toList([
                class$("px-2 py-1 text-xs rounded bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300")
              ]), toList([text2("Todo")]));
            } else if ($ instanceof InProgress) {
              return span(toList([
                class$("px-2 py-1 text-xs rounded bg-blue-100 dark:bg-blue-900 text-blue-700 dark:text-blue-300")
              ]), toList([text2("In Progress")]));
            } else {
              return span(toList([
                class$("px-2 py-1 text-xs rounded bg-green-100 dark:bg-green-900 text-green-700 dark:text-green-300")
              ]), toList([text2("Done")]));
            }
          })(),
          (() => {
            let $ = task.priority;
            if ($ instanceof High) {
              return span(toList([
                class$("px-2 py-1 text-xs rounded bg-red-100 dark:bg-red-900 text-red-700 dark:text-red-300")
              ]), toList([text2("High Priority")]));
            } else if ($ instanceof Medium) {
              return span(toList([
                class$("px-2 py-1 text-xs rounded bg-yellow-100 dark:bg-yellow-900 text-yellow-700 dark:text-yellow-300")
              ]), toList([text2("Medium Priority")]));
            } else if ($ instanceof Low) {
              return span(toList([
                class$("px-2 py-1 text-xs rounded bg-blue-100 dark:bg-blue-900 text-blue-700 dark:text-blue-300")
              ]), toList([text2("Low Priority")]));
            } else {
              return span(toList([]), toList([]));
            }
          })()
        ]))
      ])),
      button(toList([
        class$("text-gray-400 hover:text-gray-600 dark:hover:text-gray-200"),
        on_click(on_close())
      ]), toList([
        span(toList([class$("text-xl")]), toList([text2("X")]))
      ]))
    ])),
    (() => {
      let $ = task.description !== "";
      if ($) {
        return div(toList([class$("mb-4")]), toList([
          h3(toList([
            class$("text-sm font-medium text-gray-700 dark:text-gray-300 mb-1")
          ]), toList([text2("Description")])),
          p(toList([class$("text-gray-600 dark:text-gray-400")]), toList([text2(task.description)]))
        ]));
      } else {
        return none2();
      }
    })(),
    (() => {
      let $ = task.due_date;
      if ($ instanceof Some) {
        let date = $[0];
        return div(toList([class$("mb-4")]), toList([
          h3(toList([
            class$("text-sm font-medium text-gray-700 dark:text-gray-300 mb-1")
          ]), toList([text2("Due Date")])),
          p(toList([class$("text-gray-600 dark:text-gray-400")]), toList([text2(date)]))
        ]));
      } else {
        return span(toList([]), toList([]));
      }
    })(),
    div(toList([class$("mb-4")]), toList([
      h3(toList([
        class$("text-sm font-medium text-gray-700 dark:text-gray-300 mb-2")
      ]), toList([
        text2(`
 Subtasks
 `),
        (() => {
          let $ = !isEqual(task.subtasks, toList([]));
          if ($) {
            return fragment2(toList([
              text2(`
 (`),
              text2(to_string(completed_subtasks(task))),
              text2("/"),
              text2(to_string(length(task.subtasks))),
              text2(`)
 `)
            ]));
          } else {
            return none2();
          }
        })()
      ])),
      (() => {
        let $ = !isEqual(task.subtasks, toList([]));
        if ($) {
          return ul(toList([class$("space-y-2 mb-3")]), toList([
            fragment3(map2(task.subtasks, (subtask) => {
              return [
                subtask.id,
                li(toList([
                  class$("flex items-center gap-2")
                ]), toList([
                  (() => {
                    let $1 = isEqual(editing_subtask_id, new Some(subtask.id));
                    if ($1) {
                      return fragment2(toList([
                        element2("sl-input", toList([
                          attribute2("size", "small"),
                          class$("flex-1"),
                          value(editing_subtask_text),
                          on("sl-input", on_edit_subtask_input),
                          attribute2("autofocus", "")
                        ]), toList([])),
                        element2("sl-icon-button", toList([
                          name("check"),
                          attribute2("label", "Save"),
                          class$("text-green-500 hover:text-green-600"),
                          on_click(on_save_edit_subtask(subtask.id))
                        ]), toList([])),
                        element2("sl-icon-button", toList([
                          name("x"),
                          attribute2("label", "Cancel"),
                          class$("text-gray-400 hover:text-gray-600"),
                          on_click(on_cancel_edit_subtask())
                        ]), toList([]))
                      ]));
                    } else {
                      return fragment2(toList([
                        input(toList([
                          type_("checkbox"),
                          checked(subtask.completed),
                          on_click(on_toggle_subtask(subtask.id)),
                          class$("rounded")
                        ])),
                        (() => {
                          let $2 = subtask.completed;
                          if ($2) {
                            return span(toList([
                              class$("flex-1 text-gray-500 dark:text-gray-400 line-through cursor-pointer"),
                              on_click(on_start_edit_subtask(subtask.id, subtask.text))
                            ]), toList([text2(subtask.text)]));
                          } else {
                            return span(toList([
                              class$("flex-1 text-gray-700 dark:text-gray-300 cursor-pointer hover:text-blue-500"),
                              on_click(on_start_edit_subtask(subtask.id, subtask.text))
                            ]), toList([text2(subtask.text)]));
                          }
                        })(),
                        element2("sl-icon-button", toList([
                          name("trash"),
                          attribute2("label", "Delete subtask"),
                          class$("text-gray-400 hover:text-red-500"),
                          on_click(on_delete_subtask(subtask.id))
                        ]), toList([]))
                      ]));
                    }
                  })()
                ]))
              ];
            }))
          ]));
        } else {
          return none2();
        }
      })(),
      div(toList([class$("flex gap-2")]), toList([
        element2("sl-input", toList([
          placeholder("Add a subtask..."),
          attribute2("size", "small"),
          class$("flex-1 subtask-input"),
          value(new_subtask_text),
          on("sl-input", on_subtask_input),
          on("keydown", on_add_subtask_keydown)
        ]), toList([
          element2("sl-icon", toList([
            name("plus-circle"),
            attribute2("slot", "prefix")
          ]), toList([]))
        ])),
        element2("sl-button", toList([
          attribute2("size", "small"),
          attribute2("variant", "default"),
          on_click(on_add_subtask_click())
        ]), toList([text2(`
 Add
 `)]))
      ]))
    ])),
    div(toList([
      class$("flex items-center gap-2 pt-4 border-t border-gray-200 dark:border-gray-700")
    ]), toList([
      element2("sl-button", toList([
        attribute2("variant", "primary"),
        on_click(on_edit())
      ]), toList([text2("Edit")])),
      element2("sl-button", toList([
        attribute2("variant", "default"),
        on_click(on_toggle_status())
      ]), toList([text2("Toggle Status")])),
      element2("sl-button", toList([
        attribute2("variant", "danger"),
        on_click(on_delete())
      ]), toList([text2("Delete")]))
    ]))
  ]));
}

// build/dev/javascript/example_08_complete/components/tasks/task_list.mjs
function render11(tasks, selected_task_id, on_click2) {
  return div(toList([class$("space-y-3")]), toList([
    fragment3(index_map(tasks, (task, idx) => {
      return [
        to_string(idx),
        div(toList([class$("task-item")]), toList([
          (() => {
            let $ = isEqual(selected_task_id, new Some(task.id));
            if ($) {
              return div(toList([
                class$("ring-2 ring-blue-500 rounded-lg")
              ]), toList([
                div(toList([
                  class$("p-4 bg-blue-50 dark:bg-blue-900/30 rounded-lg")
                ]), toList([
                  h3(toList([
                    class$("font-medium dark:text-white")
                  ]), toList([text2(task.title)])),
                  p(toList([
                    class$("text-sm text-gray-600 dark:text-gray-400")
                  ]), toList([text2(task.description)]))
                ]))
              ]));
            } else {
              return div(toList([class$("rounded-lg")]), toList([
                div(toList([
                  class$("p-4 bg-white dark:bg-gray-800 border dark:border-gray-700 rounded-lg hover:shadow-md cursor-pointer"),
                  on_click(on_click2(task.id))
                ]), toList([
                  h3(toList([
                    class$("font-medium dark:text-white")
                  ]), toList([text2(task.title)])),
                  p(toList([
                    class$("text-sm text-gray-600 dark:text-gray-400")
                  ]), toList([text2(task.description)]))
                ]))
              ]));
            }
          })()
        ]))
      ];
    }))
  ]));
}

// build/dev/javascript/example_08_complete/ffi.mjs
function now() {
  return Date.now();
}
function stringContains(haystack, needle) {
  return haystack.includes(needle);
}
function stringLowercase(s) {
  return s.toLowerCase();
}
function applyDarkMode(enabled) {
  if (enabled) {
    document.documentElement.classList.add("dark", "sl-theme-dark");
    document.documentElement.classList.remove("sl-theme-light");
    localStorage.setItem("dark_mode", "true");
  } else {
    document.documentElement.classList.remove("dark", "sl-theme-dark");
    document.documentElement.classList.add("sl-theme-light");
    localStorage.setItem("dark_mode", "false");
  }
  return;
}
function getDarkModePreference() {
  const stored = localStorage.getItem("dark_mode");
  if (stored !== null) {
    return stored === "true";
  }
  return window.matchMedia("(prefers-color-scheme: dark)").matches;
}

// build/dev/javascript/example_08_complete/msg.mjs
class NoOp extends CustomType {
}
class ToggleSidebar extends CustomType {
}
class ToggleDarkMode extends CustomType {
}
class SetView extends CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
class SetFilter extends CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
class SetSort extends CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
class UpdateSearchQuery extends CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
class ClearSearch extends CustomType {
}
class SelectTask extends CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
class DeselectTask extends CustomType {
}
class CreateTask extends CustomType {
}
class UpdateTask extends CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
class DeleteTask extends CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
class ToggleTaskStatus extends CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
class SetTaskStatus extends CustomType {
  constructor($0, $1) {
    super();
    this[0] = $0;
    this[1] = $1;
  }
}
class ToggleSubtask extends CustomType {
  constructor($0, $1) {
    super();
    this[0] = $0;
    this[1] = $1;
  }
}
class UpdateNewSubtaskText extends CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
class SubmitNewSubtask extends CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
class AddSubtask extends CustomType {
  constructor($0, $1) {
    super();
    this[0] = $0;
    this[1] = $1;
  }
}
class DeleteSubtask extends CustomType {
  constructor($0, $1) {
    super();
    this[0] = $0;
    this[1] = $1;
  }
}
class StartEditSubtask extends CustomType {
  constructor($0, $1) {
    super();
    this[0] = $0;
    this[1] = $1;
  }
}
class UpdateEditSubtaskText extends CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
class SaveEditSubtask extends CustomType {
  constructor($0, $1) {
    super();
    this[0] = $0;
    this[1] = $1;
  }
}
class CancelEditSubtask extends CustomType {
}
class SelectProject extends CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
class DeselectProject extends CustomType {
}
class CreateProject extends CustomType {
}
class OpenAddTaskDialog extends CustomType {
}
class OpenEditTaskDialog extends CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
class OpenDeleteConfirmDialog extends CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
class OpenExportDialog extends CustomType {
}
class CloseDialog extends CustomType {
}
class UpdateFormTitle extends CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
class UpdateFormDescription extends CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
class UpdateFormPriority extends CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
class UpdateFormDueDate extends CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
class UpdateFormProject extends CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
class ClearFormProject extends CustomType {
}
class SubmitForm extends CustomType {
}
class ShowToast extends CustomType {
  constructor($0, $1) {
    super();
    this[0] = $0;
    this[1] = $1;
  }
}
class DismissToast extends CustomType {
}
class CompleteAllTasks extends CustomType {
}
class DeleteCompletedTasks extends CustomType {
}
class ExportTasks extends CustomType {
}
class ImportTasks extends CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
class ClearAllData extends CustomType {
}

// build/dev/javascript/example_08_complete/update.mjs
function next_status(status) {
  if (status instanceof Todo) {
    return new InProgress;
  } else if (status instanceof InProgress) {
    return new Done;
  } else {
    return new Todo;
  }
}
function update_task_from_form(task, form) {
  return new Task(task.id, form.title, form.description, task.status, form.priority, form.due_date, form.project_id, task.subtasks, task.created_at, "2024-01-20");
}
function form_from_task(task) {
  return new FormState(task.title, task.description, task.priority, task.due_date, task.project_id);
}
function find_task(loop$tasks, loop$id) {
  while (true) {
    let tasks = loop$tasks;
    let id = loop$id;
    if (tasks instanceof Empty) {
      return new None;
    } else {
      let first = tasks.head;
      let rest = tasks.tail;
      let $ = first.id === id;
      if ($) {
        return new Some(first);
      } else {
        loop$tasks = rest;
        loop$id = id;
      }
    }
  }
}
function generate_id() {
  return inspect2(now());
}
function create_task_from_form(model) {
  return new Task(generate_id(), model.form.title, model.form.description, new Todo, model.form.priority, model.form.due_date, model.form.project_id, toList([]), "2024-01-20", "2024-01-20");
}
function update2(loop$model, loop$msg) {
  while (true) {
    let model = loop$model;
    let msg = loop$msg;
    if (msg instanceof NoOp) {
      return model;
    } else if (msg instanceof ToggleSidebar) {
      return new Model(model.tasks, model.projects, model.current_view, model.current_filter, model.sort_by, model.search_query, !model.sidebar_open, model.selected_task_id, model.editing_task, model.dialog_open, model.toast, model.form, model.dark_mode, model.new_subtask_text, model.editing_subtask_id, model.editing_subtask_text);
    } else if (msg instanceof ToggleDarkMode) {
      let new_dark_mode = !model.dark_mode;
      applyDarkMode(new_dark_mode);
      return new Model(model.tasks, model.projects, model.current_view, model.current_filter, model.sort_by, model.search_query, model.sidebar_open, model.selected_task_id, model.editing_task, model.dialog_open, model.toast, model.form, new_dark_mode, model.new_subtask_text, model.editing_subtask_id, model.editing_subtask_text);
    } else if (msg instanceof SetView) {
      let view = msg[0];
      return new Model(model.tasks, model.projects, view, model.current_filter, model.sort_by, model.search_query, model.sidebar_open, model.selected_task_id, model.editing_task, model.dialog_open, model.toast, model.form, model.dark_mode, model.new_subtask_text, model.editing_subtask_id, model.editing_subtask_text);
    } else if (msg instanceof SetFilter) {
      let filter3 = msg[0];
      return new Model(model.tasks, model.projects, model.current_view, filter3, model.sort_by, model.search_query, model.sidebar_open, model.selected_task_id, model.editing_task, model.dialog_open, model.toast, model.form, model.dark_mode, model.new_subtask_text, model.editing_subtask_id, model.editing_subtask_text);
    } else if (msg instanceof SetSort) {
      let sort2 = msg[0];
      return new Model(model.tasks, model.projects, model.current_view, model.current_filter, sort2, model.search_query, model.sidebar_open, model.selected_task_id, model.editing_task, model.dialog_open, model.toast, model.form, model.dark_mode, model.new_subtask_text, model.editing_subtask_id, model.editing_subtask_text);
    } else if (msg instanceof UpdateSearchQuery) {
      let query = msg[0];
      return new Model(model.tasks, model.projects, model.current_view, model.current_filter, model.sort_by, query, model.sidebar_open, model.selected_task_id, model.editing_task, model.dialog_open, model.toast, model.form, model.dark_mode, model.new_subtask_text, model.editing_subtask_id, model.editing_subtask_text);
    } else if (msg instanceof ClearSearch) {
      return new Model(model.tasks, model.projects, model.current_view, model.current_filter, model.sort_by, "", model.sidebar_open, model.selected_task_id, model.editing_task, model.dialog_open, model.toast, model.form, model.dark_mode, model.new_subtask_text, model.editing_subtask_id, model.editing_subtask_text);
    } else if (msg instanceof SelectTask) {
      let id = msg[0];
      return new Model(model.tasks, model.projects, model.current_view, model.current_filter, model.sort_by, model.search_query, model.sidebar_open, new Some(id), model.editing_task, model.dialog_open, model.toast, model.form, model.dark_mode, model.new_subtask_text, model.editing_subtask_id, model.editing_subtask_text);
    } else if (msg instanceof DeselectTask) {
      return new Model(model.tasks, model.projects, model.current_view, model.current_filter, model.sort_by, model.search_query, model.sidebar_open, new None, model.editing_task, model.dialog_open, model.toast, model.form, model.dark_mode, model.new_subtask_text, model.editing_subtask_id, model.editing_subtask_text);
    } else if (msg instanceof CreateTask) {
      let new_task = create_task_from_form(model);
      return new Model(prepend(new_task, model.tasks), model.projects, model.current_view, model.current_filter, model.sort_by, model.search_query, model.sidebar_open, new Some(new_task.id), model.editing_task, new NoDialog, new Some(["Task created successfully", new Success]), empty_form(), model.dark_mode, model.new_subtask_text, model.editing_subtask_id, model.editing_subtask_text);
    } else if (msg instanceof UpdateTask) {
      let id = msg[0];
      let updated_tasks = map2(model.tasks, (t) => {
        let $ = t.id === id;
        if ($) {
          return update_task_from_form(t, model.form);
        } else {
          return t;
        }
      });
      return new Model(updated_tasks, model.projects, model.current_view, model.current_filter, model.sort_by, model.search_query, model.sidebar_open, model.selected_task_id, model.editing_task, new NoDialog, new Some(["Task updated successfully", new Success]), empty_form(), model.dark_mode, model.new_subtask_text, model.editing_subtask_id, model.editing_subtask_text);
    } else if (msg instanceof DeleteTask) {
      let id = msg[0];
      let filtered_tasks = filter(model.tasks, (t) => {
        return t.id !== id;
      });
      return new Model(filtered_tasks, model.projects, model.current_view, model.current_filter, model.sort_by, model.search_query, model.sidebar_open, new None, model.editing_task, new NoDialog, new Some(["Task deleted", new Info]), model.form, model.dark_mode, model.new_subtask_text, model.editing_subtask_id, model.editing_subtask_text);
    } else if (msg instanceof ToggleTaskStatus) {
      let id = msg[0];
      let updated_tasks = map2(model.tasks, (t) => {
        let $ = t.id === id;
        if ($) {
          return new Task(t.id, t.title, t.description, next_status(t.status), t.priority, t.due_date, t.project_id, t.subtasks, t.created_at, t.updated_at);
        } else {
          return t;
        }
      });
      return new Model(updated_tasks, model.projects, model.current_view, model.current_filter, model.sort_by, model.search_query, model.sidebar_open, model.selected_task_id, model.editing_task, model.dialog_open, model.toast, model.form, model.dark_mode, model.new_subtask_text, model.editing_subtask_id, model.editing_subtask_text);
    } else if (msg instanceof SetTaskStatus) {
      let id = msg[0];
      let status = msg[1];
      let updated_tasks = map2(model.tasks, (t) => {
        let $ = t.id === id;
        if ($) {
          return new Task(t.id, t.title, t.description, status, t.priority, t.due_date, t.project_id, t.subtasks, t.created_at, t.updated_at);
        } else {
          return t;
        }
      });
      return new Model(updated_tasks, model.projects, model.current_view, model.current_filter, model.sort_by, model.search_query, model.sidebar_open, model.selected_task_id, model.editing_task, model.dialog_open, model.toast, model.form, model.dark_mode, model.new_subtask_text, model.editing_subtask_id, model.editing_subtask_text);
    } else if (msg instanceof ToggleSubtask) {
      let task_id = msg[0];
      let subtask_id = msg[1];
      let updated_tasks = map2(model.tasks, (t) => {
        let $ = t.id === task_id;
        if ($) {
          return new Task(t.id, t.title, t.description, t.status, t.priority, t.due_date, t.project_id, map2(t.subtasks, (s) => {
            let $1 = s.id === subtask_id;
            if ($1) {
              return new Subtask(s.id, s.text, !s.completed);
            } else {
              return s;
            }
          }), t.created_at, t.updated_at);
        } else {
          return t;
        }
      });
      return new Model(updated_tasks, model.projects, model.current_view, model.current_filter, model.sort_by, model.search_query, model.sidebar_open, model.selected_task_id, model.editing_task, model.dialog_open, model.toast, model.form, model.dark_mode, model.new_subtask_text, model.editing_subtask_id, model.editing_subtask_text);
    } else if (msg instanceof UpdateNewSubtaskText) {
      let text4 = msg[0];
      return new Model(model.tasks, model.projects, model.current_view, model.current_filter, model.sort_by, model.search_query, model.sidebar_open, model.selected_task_id, model.editing_task, model.dialog_open, model.toast, model.form, model.dark_mode, text4, model.editing_subtask_id, model.editing_subtask_text);
    } else if (msg instanceof SubmitNewSubtask) {
      let task_id = msg[0];
      let $ = model.new_subtask_text;
      if ($ === "") {
        return model;
      } else {
        let text4 = $;
        let updated_tasks = map2(model.tasks, (t) => {
          let $1 = t.id === task_id;
          if ($1) {
            let new_subtask = new Subtask(task_id + "-" + generate_id(), text4, false);
            return new Task(t.id, t.title, t.description, t.status, t.priority, t.due_date, t.project_id, append(t.subtasks, toList([new_subtask])), t.created_at, t.updated_at);
          } else {
            return t;
          }
        });
        return new Model(updated_tasks, model.projects, model.current_view, model.current_filter, model.sort_by, model.search_query, model.sidebar_open, model.selected_task_id, model.editing_task, model.dialog_open, model.toast, model.form, model.dark_mode, "", model.editing_subtask_id, model.editing_subtask_text);
      }
    } else if (msg instanceof AddSubtask) {
      let task_id = msg[0];
      let text4 = msg[1];
      if (text4 === "") {
        return model;
      } else {
        let updated_tasks = map2(model.tasks, (t) => {
          let $ = t.id === task_id;
          if ($) {
            let new_subtask = new Subtask(task_id + "-" + generate_id(), text4, false);
            return new Task(t.id, t.title, t.description, t.status, t.priority, t.due_date, t.project_id, append(t.subtasks, toList([new_subtask])), t.created_at, t.updated_at);
          } else {
            return t;
          }
        });
        return new Model(updated_tasks, model.projects, model.current_view, model.current_filter, model.sort_by, model.search_query, model.sidebar_open, model.selected_task_id, model.editing_task, model.dialog_open, model.toast, model.form, model.dark_mode, model.new_subtask_text, model.editing_subtask_id, model.editing_subtask_text);
      }
    } else if (msg instanceof DeleteSubtask) {
      let task_id = msg[0];
      let subtask_id = msg[1];
      let updated_tasks = map2(model.tasks, (t) => {
        let $ = t.id === task_id;
        if ($) {
          return new Task(t.id, t.title, t.description, t.status, t.priority, t.due_date, t.project_id, filter(t.subtasks, (s) => {
            return s.id !== subtask_id;
          }), t.created_at, t.updated_at);
        } else {
          return t;
        }
      });
      return new Model(updated_tasks, model.projects, model.current_view, model.current_filter, model.sort_by, model.search_query, model.sidebar_open, model.selected_task_id, model.editing_task, model.dialog_open, model.toast, model.form, model.dark_mode, model.new_subtask_text, model.editing_subtask_id, model.editing_subtask_text);
    } else if (msg instanceof StartEditSubtask) {
      let subtask_id = msg[0];
      let current_text = msg[1];
      return new Model(model.tasks, model.projects, model.current_view, model.current_filter, model.sort_by, model.search_query, model.sidebar_open, model.selected_task_id, model.editing_task, model.dialog_open, model.toast, model.form, model.dark_mode, model.new_subtask_text, new Some(subtask_id), current_text);
    } else if (msg instanceof UpdateEditSubtaskText) {
      let text4 = msg[0];
      return new Model(model.tasks, model.projects, model.current_view, model.current_filter, model.sort_by, model.search_query, model.sidebar_open, model.selected_task_id, model.editing_task, model.dialog_open, model.toast, model.form, model.dark_mode, model.new_subtask_text, model.editing_subtask_id, text4);
    } else if (msg instanceof SaveEditSubtask) {
      let task_id = msg[0];
      let subtask_id = msg[1];
      let $ = model.editing_subtask_text;
      if ($ === "") {
        return new Model(model.tasks, model.projects, model.current_view, model.current_filter, model.sort_by, model.search_query, model.sidebar_open, model.selected_task_id, model.editing_task, model.dialog_open, model.toast, model.form, model.dark_mode, model.new_subtask_text, new None, "");
      } else {
        let text4 = $;
        let updated_tasks = map2(model.tasks, (t) => {
          let $1 = t.id === task_id;
          if ($1) {
            return new Task(t.id, t.title, t.description, t.status, t.priority, t.due_date, t.project_id, map2(t.subtasks, (s) => {
              let $2 = s.id === subtask_id;
              if ($2) {
                return new Subtask(s.id, text4, s.completed);
              } else {
                return s;
              }
            }), t.created_at, t.updated_at);
          } else {
            return t;
          }
        });
        return new Model(updated_tasks, model.projects, model.current_view, model.current_filter, model.sort_by, model.search_query, model.sidebar_open, model.selected_task_id, model.editing_task, model.dialog_open, model.toast, model.form, model.dark_mode, model.new_subtask_text, new None, "");
      }
    } else if (msg instanceof CancelEditSubtask) {
      return new Model(model.tasks, model.projects, model.current_view, model.current_filter, model.sort_by, model.search_query, model.sidebar_open, model.selected_task_id, model.editing_task, model.dialog_open, model.toast, model.form, model.dark_mode, model.new_subtask_text, new None, "");
    } else if (msg instanceof SelectProject) {
      let id = msg[0];
      return new Model(model.tasks, model.projects, model.current_view, new ByProject(id), model.sort_by, model.search_query, model.sidebar_open, model.selected_task_id, model.editing_task, model.dialog_open, model.toast, model.form, model.dark_mode, model.new_subtask_text, model.editing_subtask_id, model.editing_subtask_text);
    } else if (msg instanceof DeselectProject) {
      return new Model(model.tasks, model.projects, model.current_view, new All, model.sort_by, model.search_query, model.sidebar_open, model.selected_task_id, model.editing_task, model.dialog_open, model.toast, model.form, model.dark_mode, model.new_subtask_text, model.editing_subtask_id, model.editing_subtask_text);
    } else if (msg instanceof CreateProject) {
      return model;
    } else if (msg instanceof OpenAddTaskDialog) {
      return new Model(model.tasks, model.projects, model.current_view, model.current_filter, model.sort_by, model.search_query, model.sidebar_open, model.selected_task_id, model.editing_task, new AddTaskDialog, model.toast, empty_form(), model.dark_mode, model.new_subtask_text, model.editing_subtask_id, model.editing_subtask_text);
    } else if (msg instanceof OpenEditTaskDialog) {
      let id = msg[0];
      let task = find_task(model.tasks, id);
      if (task instanceof Some) {
        let t = task[0];
        return new Model(model.tasks, model.projects, model.current_view, model.current_filter, model.sort_by, model.search_query, model.sidebar_open, model.selected_task_id, model.editing_task, new EditTaskDialog(id), model.toast, form_from_task(t), model.dark_mode, model.new_subtask_text, model.editing_subtask_id, model.editing_subtask_text);
      } else {
        return model;
      }
    } else if (msg instanceof OpenDeleteConfirmDialog) {
      let id = msg[0];
      return new Model(model.tasks, model.projects, model.current_view, model.current_filter, model.sort_by, model.search_query, model.sidebar_open, model.selected_task_id, model.editing_task, new DeleteConfirmDialog(id), model.toast, model.form, model.dark_mode, model.new_subtask_text, model.editing_subtask_id, model.editing_subtask_text);
    } else if (msg instanceof OpenExportDialog) {
      return new Model(model.tasks, model.projects, model.current_view, model.current_filter, model.sort_by, model.search_query, model.sidebar_open, model.selected_task_id, model.editing_task, new ExportDialog, model.toast, model.form, model.dark_mode, model.new_subtask_text, model.editing_subtask_id, model.editing_subtask_text);
    } else if (msg instanceof CloseDialog) {
      return new Model(model.tasks, model.projects, model.current_view, model.current_filter, model.sort_by, model.search_query, model.sidebar_open, model.selected_task_id, model.editing_task, new NoDialog, model.toast, model.form, model.dark_mode, model.new_subtask_text, model.editing_subtask_id, model.editing_subtask_text);
    } else if (msg instanceof UpdateFormTitle) {
      let title = msg[0];
      return new Model(model.tasks, model.projects, model.current_view, model.current_filter, model.sort_by, model.search_query, model.sidebar_open, model.selected_task_id, model.editing_task, model.dialog_open, model.toast, (() => {
        let _record = model.form;
        return new FormState(title, _record.description, _record.priority, _record.due_date, _record.project_id);
      })(), model.dark_mode, model.new_subtask_text, model.editing_subtask_id, model.editing_subtask_text);
    } else if (msg instanceof UpdateFormDescription) {
      let desc = msg[0];
      return new Model(model.tasks, model.projects, model.current_view, model.current_filter, model.sort_by, model.search_query, model.sidebar_open, model.selected_task_id, model.editing_task, model.dialog_open, model.toast, (() => {
        let _record = model.form;
        return new FormState(_record.title, desc, _record.priority, _record.due_date, _record.project_id);
      })(), model.dark_mode, model.new_subtask_text, model.editing_subtask_id, model.editing_subtask_text);
    } else if (msg instanceof UpdateFormPriority) {
      let priority = msg[0];
      return new Model(model.tasks, model.projects, model.current_view, model.current_filter, model.sort_by, model.search_query, model.sidebar_open, model.selected_task_id, model.editing_task, model.dialog_open, model.toast, (() => {
        let _record = model.form;
        return new FormState(_record.title, _record.description, priority, _record.due_date, _record.project_id);
      })(), model.dark_mode, model.new_subtask_text, model.editing_subtask_id, model.editing_subtask_text);
    } else if (msg instanceof UpdateFormDueDate) {
      let date = msg[0];
      let _block;
      if (date === "") {
        _block = new None;
      } else {
        let d = date;
        _block = new Some(d);
      }
      let due = _block;
      return new Model(model.tasks, model.projects, model.current_view, model.current_filter, model.sort_by, model.search_query, model.sidebar_open, model.selected_task_id, model.editing_task, model.dialog_open, model.toast, (() => {
        let _record = model.form;
        return new FormState(_record.title, _record.description, _record.priority, due, _record.project_id);
      })(), model.dark_mode, model.new_subtask_text, model.editing_subtask_id, model.editing_subtask_text);
    } else if (msg instanceof UpdateFormProject) {
      let id = msg[0];
      return new Model(model.tasks, model.projects, model.current_view, model.current_filter, model.sort_by, model.search_query, model.sidebar_open, model.selected_task_id, model.editing_task, model.dialog_open, model.toast, (() => {
        let _record = model.form;
        return new FormState(_record.title, _record.description, _record.priority, _record.due_date, new Some(id));
      })(), model.dark_mode, model.new_subtask_text, model.editing_subtask_id, model.editing_subtask_text);
    } else if (msg instanceof ClearFormProject) {
      return new Model(model.tasks, model.projects, model.current_view, model.current_filter, model.sort_by, model.search_query, model.sidebar_open, model.selected_task_id, model.editing_task, model.dialog_open, model.toast, (() => {
        let _record = model.form;
        return new FormState(_record.title, _record.description, _record.priority, _record.due_date, new None);
      })(), model.dark_mode, model.new_subtask_text, model.editing_subtask_id, model.editing_subtask_text);
    } else if (msg instanceof SubmitForm) {
      let $ = model.dialog_open;
      if ($ instanceof AddTaskDialog) {
        loop$model = model;
        loop$msg = new CreateTask;
      } else if ($ instanceof EditTaskDialog) {
        let id = $[0];
        loop$model = model;
        loop$msg = new UpdateTask(id);
      } else {
        return model;
      }
    } else if (msg instanceof ShowToast) {
      let message = msg[0];
      let toast_type = msg[1];
      return new Model(model.tasks, model.projects, model.current_view, model.current_filter, model.sort_by, model.search_query, model.sidebar_open, model.selected_task_id, model.editing_task, model.dialog_open, new Some([message, toast_type]), model.form, model.dark_mode, model.new_subtask_text, model.editing_subtask_id, model.editing_subtask_text);
    } else if (msg instanceof DismissToast) {
      return new Model(model.tasks, model.projects, model.current_view, model.current_filter, model.sort_by, model.search_query, model.sidebar_open, model.selected_task_id, model.editing_task, model.dialog_open, new None, model.form, model.dark_mode, model.new_subtask_text, model.editing_subtask_id, model.editing_subtask_text);
    } else if (msg instanceof CompleteAllTasks) {
      let updated_tasks = map2(model.tasks, (t) => {
        return new Task(t.id, t.title, t.description, new Done, t.priority, t.due_date, t.project_id, t.subtasks, t.created_at, t.updated_at);
      });
      return new Model(updated_tasks, model.projects, model.current_view, model.current_filter, model.sort_by, model.search_query, model.sidebar_open, model.selected_task_id, model.editing_task, model.dialog_open, new Some(["All tasks completed", new Success]), model.form, model.dark_mode, model.new_subtask_text, model.editing_subtask_id, model.editing_subtask_text);
    } else if (msg instanceof DeleteCompletedTasks) {
      let filtered = filter(model.tasks, (t) => {
        return !(t.status instanceof Done);
      });
      return new Model(filtered, model.projects, model.current_view, model.current_filter, model.sort_by, model.search_query, model.sidebar_open, model.selected_task_id, model.editing_task, model.dialog_open, new Some(["Completed tasks deleted", new Info]), model.form, model.dark_mode, model.new_subtask_text, model.editing_subtask_id, model.editing_subtask_text);
    } else if (msg instanceof ExportTasks) {
      return model;
    } else if (msg instanceof ImportTasks) {
      return model;
    } else if (msg instanceof ClearAllData) {
      return new Model(toList([]), toList([]), model.current_view, model.current_filter, model.sort_by, model.search_query, model.sidebar_open, model.selected_task_id, model.editing_task, model.dialog_open, new Some(["All data cleared", new Warning]), model.form, model.dark_mode, model.new_subtask_text, model.editing_subtask_id, model.editing_subtask_text);
    } else {
      let key = msg[0];
      if (key === "n") {
        loop$model = model;
        loop$msg = new OpenAddTaskDialog;
      } else if (key === "Escape") {
        let $ = model.dialog_open;
        if ($ instanceof NoDialog) {
          return new Model(model.tasks, model.projects, model.current_view, model.current_filter, model.sort_by, model.search_query, model.sidebar_open, new None, model.editing_task, model.dialog_open, model.toast, model.form, model.dark_mode, model.new_subtask_text, model.editing_subtask_id, model.editing_subtask_text);
        } else {
          return new Model(model.tasks, model.projects, model.current_view, model.current_filter, model.sort_by, model.search_query, model.sidebar_open, model.selected_task_id, model.editing_task, new NoDialog, model.toast, model.form, model.dark_mode, model.new_subtask_text, model.editing_subtask_id, model.editing_subtask_text);
        }
      } else if (key === "/") {
        return model;
      } else {
        return model;
      }
    }
  }
}

// build/dev/javascript/example_08_complete/app.mjs
var FILEPATH = "src/app.gleam";
function init(_) {
  let dark_mode = getDarkModePreference();
  applyDarkMode(dark_mode);
  let _record = initial_model();
  return new Model(_record.tasks, _record.projects, _record.current_view, _record.current_filter, _record.sort_by, _record.search_query, _record.sidebar_open, _record.selected_task_id, _record.editing_task, _record.dialog_open, _record.toast, _record.form, dark_mode, _record.new_subtask_text, _record.editing_subtask_id, _record.editing_subtask_text);
}
function view_empty_state() {
  return render("No tasks", "No tasks yet", "Create your first task to get started.", "Create Task", () => {
    return new OpenAddTaskDialog;
  });
}
function find_task2(tasks, id) {
  let _pipe = find(tasks, (t) => {
    return t.id === id;
  });
  return from_result(_pipe);
}
function close_dialog_decoder() {
  return success(new CloseDialog);
}
function view_dialogs(model) {
  return div(toList([]), toList([
    render3((() => {
      let $ = model.dialog_open;
      if ($ instanceof DeleteConfirmDialog) {
        return true;
      } else {
        return false;
      }
    })(), "Delete Task", "Are you sure you want to delete this task? This action cannot be undone.", "Delete", () => {
      let $ = model.dialog_open;
      if ($ instanceof DeleteConfirmDialog) {
        let id = $[0];
        return new DeleteTask(id);
      } else {
        return new CloseDialog;
      }
    }, () => {
      return new CloseDialog;
    }, close_dialog_decoder()),
    render4(model.dialog_open instanceof ExportDialog, () => {
      return new ExportTasks;
    }, () => {
      return new ImportTasks("");
    }, () => {
      return new ClearAllData;
    }, () => {
      return new CloseDialog;
    }, close_dialog_decoder())
  ]));
}
function view_toast(model) {
  let $ = model.toast;
  if ($ instanceof Some) {
    let message = $[0][0];
    let toast_type = $[0][1];
    return render2(message, toast_type, true, () => {
      return new DismissToast;
    });
  } else {
    return text3("");
  }
}
function get_current_project_id(model) {
  let $ = model.current_filter;
  if ($ instanceof ByProject) {
    let id = $[0];
    return new Some(id);
  } else {
    return new None;
  }
}
function view_sidebar(model) {
  return div(toList([]), toList([
    (() => {
      let $ = model.sidebar_open;
      if ($) {
        return div(toList([
          class$("fixed inset-0 bg-black bg-opacity-50 z-40 lg:hidden"),
          on_click(new ToggleSidebar)
        ]), toList([]));
      } else {
        return text3("");
      }
    })(),
    aside(toList([
      class$("fixed inset-y-0 left-0 z-50 w-64 bg-white dark:bg-gray-800 transform transition-transform duration-300 ease-in-out lg:translate-x-0 lg:static lg:z-auto " + (() => {
        let $ = model.sidebar_open;
        if ($) {
          return "translate-x-0";
        } else {
          return "-translate-x-full";
        }
      })())
    ]), toList([
      render8(model.projects, get_current_project_id(model), () => {
        return new DeselectProject;
      }, (id) => {
        return new SelectProject(id);
      }, () => {
        return new CreateProject;
      })
    ]))
  ]));
}
function contains_ignore_case(haystack, needle) {
  let h = stringLowercase(haystack);
  let n = stringLowercase(needle);
  return stringContains(h, n);
}
function filter_tasks(model) {
  let by_filter = filter(model.tasks, (t) => {
    let $2 = model.current_filter;
    if ($2 instanceof All) {
      return true;
    } else if ($2 instanceof ByProject) {
      let id = $2[0];
      return isEqual(t.project_id, new Some(id));
    } else if ($2 instanceof Today) {
      return false;
    } else {
      return false;
    }
  });
  let $ = model.search_query;
  if ($ === "") {
    return by_filter;
  } else {
    let query = $;
    return filter(by_filter, (t) => {
      return contains_ignore_case(t.title, query);
    });
  }
}
function decode_input_value(to_msg) {
  let _pipe = at(toList(["target", "value"]), string2);
  return map3(_pipe, to_msg);
}
function view_task_form(model, title, _) {
  return div(toList([class$("p-6")]), toList([
    div(toList([class$("flex items-center justify-between mb-6")]), toList([
      h2(toList([
        class$("text-xl font-semibold text-gray-900 dark:text-white")
      ]), toList([text3(title)])),
      button(toList([
        class$("text-gray-400 hover:text-gray-600 dark:hover:text-gray-200"),
        on_click(new CloseDialog)
      ]), toList([
        span(toList([class$("text-xl")]), toList([text3("X")]))
      ]))
    ])),
    div(toList([class$("space-y-4")]), toList([
      div(toList([]), toList([
        label(toList([
          class$("block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1")
        ]), toList([text3("Title")])),
        element2("sl-input", toList([
          attribute2("value", model.form.title),
          attribute2("placeholder", "Task title"),
          on("sl-input", decode_input_value((var0) => {
            return new UpdateFormTitle(var0);
          }))
        ]), toList([]))
      ])),
      div(toList([]), toList([
        label(toList([
          class$("block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1")
        ]), toList([text3("Description")])),
        element2("sl-textarea", toList([
          attribute2("value", model.form.description),
          attribute2("placeholder", "Add details..."),
          attribute2("rows", "3"),
          on("sl-input", decode_input_value((var0) => {
            return new UpdateFormDescription(var0);
          }))
        ]), toList([]))
      ])),
      div(toList([]), toList([
        label(toList([
          class$("block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1")
        ]), toList([text3("Priority")])),
        element2("sl-select", toList([
          attribute2("value", priority_to_string(model.form.priority)),
          attribute2("hoist", ""),
          on("sl-change", decode_input_value((s) => {
            return new UpdateFormPriority(priority_from_string(s));
          }))
        ]), toList([
          element2("sl-option", toList([attribute2("value", "none")]), toList([text3("No Priority")])),
          element2("sl-option", toList([attribute2("value", "low")]), toList([text3("Low")])),
          element2("sl-option", toList([attribute2("value", "medium")]), toList([text3("Medium")])),
          element2("sl-option", toList([attribute2("value", "high")]), toList([text3("High")]))
        ]))
      ])),
      div(toList([]), toList([
        label(toList([
          class$("block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1")
        ]), toList([text3("Due Date")])),
        element2("sl-input", toList([
          attribute2("type", "date"),
          attribute2("value", (() => {
            let $ = model.form.due_date;
            if ($ instanceof Some) {
              let d = $[0];
              return d;
            } else {
              return "";
            }
          })()),
          on("sl-input", decode_input_value((var0) => {
            return new UpdateFormDueDate(var0);
          }))
        ]), toList([]))
      ]))
    ])),
    div(toList([
      class$("flex gap-2 pt-6 mt-6 border-t border-gray-200 dark:border-gray-700")
    ]), toList([
      element2("sl-button", toList([
        attribute2("variant", "default"),
        on_click(new CloseDialog)
      ]), toList([text3("Cancel")])),
      element2("sl-button", toList([
        attribute2("variant", "primary"),
        on_click(new SubmitForm)
      ]), toList([
        text3((() => {
          let $ = model.dialog_open;
          if ($ instanceof EditTaskDialog) {
            return "Save Changes";
          } else {
            return "Create Task";
          }
        })())
      ]))
    ]))
  ]));
}
function decode_sort_value() {
  let _pipe = at(toList(["target", "value"]), string2);
  return map3(_pipe, (s) => {
    if (s === "created") {
      return new SetSort(new SortByCreated);
    } else if (s === "due_date") {
      return new SetSort(new SortByDueDate);
    } else if (s === "priority") {
      return new SetSort(new SortByPriority);
    } else if (s === "title") {
      return new SetSort(new SortByTitle);
    } else {
      return new SetSort(new SortByCreated);
    }
  });
}
function view_content(model) {
  let filtered_tasks = filter_tasks(model);
  let $ = length(filtered_tasks);
  if ($ === 0) {
    return view_empty_state();
  } else {
    return div(toList([]), toList([
      render5(model.current_filter, (f) => {
        return new SetFilter(f);
      }, decode_sort_value()),
      (() => {
        let $1 = model.current_view;
        if ($1 instanceof ListView) {
          return render11(filtered_tasks, model.selected_task_id, (id) => {
            return new SelectTask(id);
          });
        } else {
          let todo_tasks = filter(filtered_tasks, (t) => {
            return t.status instanceof Todo;
          });
          let in_progress_tasks = filter(filtered_tasks, (t) => {
            return t.status instanceof InProgress;
          });
          let done_tasks = filter(filtered_tasks, (t) => {
            return t.status instanceof Done;
          });
          return render9(todo_tasks, in_progress_tasks, done_tasks, (id) => {
            return new SelectTask(id);
          });
        }
      })()
    ]));
  }
}
function decode_subtask_enter(task_id) {
  return then$(at(toList(["key"]), string2), (key) => {
    if (key === "Enter") {
      return success(new SubmitNewSubtask(task_id));
    } else {
      return success(new NoOp);
    }
  });
}
function view_task_detail(model) {
  let _block;
  let $ = model.dialog_open;
  if ($ instanceof AddTaskDialog) {
    _block = new Some(["create", new None]);
  } else if ($ instanceof EditTaskDialog) {
    let id = $[0];
    _block = new Some(["edit", find_task2(model.tasks, id)]);
  } else {
    let $1 = model.selected_task_id;
    if ($1 instanceof Some) {
      let id = $1[0];
      _block = new Some(["view", find_task2(model.tasks, id)]);
    } else {
      _block = $1;
    }
  }
  let panel_state = _block;
  if (panel_state instanceof Some) {
    let mode = panel_state[0][0];
    let maybe_task = panel_state[0][1];
    return div(toList([]), toList([
      div(toList([
        class$("fixed inset-0 bg-black bg-opacity-50 z-40"),
        on_click((() => {
          if (mode === "create") {
            return new CloseDialog;
          } else if (mode === "edit") {
            return new CloseDialog;
          } else {
            return new DeselectTask;
          }
        })())
      ]), toList([])),
      div(toList([
        class$("fixed inset-y-0 right-0 z-50 w-full max-w-md bg-white dark:bg-gray-800 shadow-xl overflow-y-auto")
      ]), toList([
        (() => {
          if (mode === "create") {
            return view_task_form(model, "New Task", new None);
          } else if (mode === "edit") {
            return view_task_form(model, "Edit Task", maybe_task);
          } else {
            if (maybe_task instanceof Some) {
              let t = maybe_task[0];
              return render10(t, model.new_subtask_text, model.editing_subtask_id, model.editing_subtask_text, () => {
                return new OpenEditTaskDialog(t.id);
              }, () => {
                return new OpenDeleteConfirmDialog(t.id);
              }, () => {
                return new ToggleTaskStatus(t.id);
              }, (subtask_id) => {
                return new ToggleSubtask(t.id, subtask_id);
              }, decode_input_value((var0) => {
                return new UpdateNewSubtaskText(var0);
              }), decode_subtask_enter(t.id), () => {
                return new SubmitNewSubtask(t.id);
              }, (subtask_id) => {
                return new DeleteSubtask(t.id, subtask_id);
              }, (subtask_id, text4) => {
                return new StartEditSubtask(subtask_id, text4);
              }, decode_input_value((var0) => {
                return new UpdateEditSubtaskText(var0);
              }), (subtask_id) => {
                return new SaveEditSubtask(t.id, subtask_id);
              }, () => {
                return new CancelEditSubtask;
              }, () => {
                return new DeselectTask;
              });
            } else {
              return text3("");
            }
          }
        })()
      ]))
    ]));
  } else {
    return text3("");
  }
}
function view(model) {
  return div(toList([class$("min-h-screen bg-gray-50 dark:bg-gray-900")]), toList([
    div(toList([class$("flex h-screen")]), toList([
      view_sidebar(model),
      div(toList([class$("flex-1 flex flex-col overflow-hidden")]), toList([
        render6(model.current_view, model.search_query, model.dark_mode, () => {
          return new ToggleSidebar;
        }, (v) => {
          return new SetView(v);
        }, decode_input_value((var0) => {
          return new UpdateSearchQuery(var0);
        }), () => {
          return new ToggleDarkMode;
        }, () => {
          return new OpenAddTaskDialog;
        }),
        main(toList([class$("flex-1 overflow-auto p-4 lg:p-6")]), toList([view_content(model)]))
      ]))
    ])),
    div(toList([class$("lg:hidden fixed bottom-0 left-0 right-0")]), toList([
      render7(model.current_view, (v) => {
        return new SetView(v);
      }, () => {
        return new OpenAddTaskDialog;
      })
    ])),
    view_task_detail(model),
    view_dialogs(model),
    view_toast(model)
  ]));
}
function main2() {
  let app = simple(init, update2, view);
  let $ = start4(app, "#app", undefined);
  if (!($ instanceof Ok)) {
    throw makeError("let_assert", FILEPATH, "app", 41, "main", "Pattern match failed, no pattern matched the value.", {
      value: $,
      start: 1348,
      end: 1397,
      pattern_start: 1359,
      pattern_end: 1364
    });
  }
  return;
}

// build/dev/javascript/example_08_complete/example_08_complete.mjs
function main3() {
  return main2();
}

// .lustre/build/example_08_complete.mjs
main3();
