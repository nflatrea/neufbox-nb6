#!/usr/bin/python3
# -*- coding: utf-8 -*-

# This tool expects data from the serial terminal in a format like this
# CFE> dn 0 0 1
# ------------------ block: 0, page: 0 ------------------
# 00000000: 10000027 00000000 80005fb0 80005fb0    ...'......_..._.
# 00000010: 80006600 800070a0 80000000 80006600    ..f...p.......f.
# 00000020: 8000e5d0 00000000 00000000 00000000    ................
# 00000030: 80002d70 80002e84 80002e7c 80004688    ..-p.......|..F.
# 00000040: 80004774 80004774 80004774 8000477c    ..Gt..Gt..Gt..G|
# 00000050: 800033d8 80004784 8000483c 80002620    ..3...G...H<..& 
# 00000060: 800025e8 800025f0 80002f44 800025d4    ..%...%.../D..%.
# 00000070: 80003088 80002d68 80002ed0 80004774    ..0...-h......Gt
# 00000080: 80004774 80004774 80002f18 800045a8    ..Gt..Gt../...E.
# 00000090: 800045b4 80004774 80004774 80004774    ..E...Gt..Gt..Gt
# 000000a0: 0000e021 04110001 00000000 00000000    ...!............
# 000000b0: 3c151fff 02bfa824 3c168000 26d600c8    <......$<...&...
# 000000c0: 04110001 00000000 03f6b022 02a02021    ...........".. !
# 000000d0: 3c1b8000 277b0030 0376d821 3c01a000    <...'{.0.v.!<...
# 000000e0: 0361d825 8f7b0000 0376d821 3c01a000    .a.%.{...v.!<...
# 000000f0: 0361d825 0360f809 00000000 3c044845    .a.%.`......<.HE
# 00000100: 34844c4f 3c1b8000 277b0030 0376d821    4.LO<...'{.0.v.!
# 00000110: 3c01a000 0361d825 8f7b0004 0376d821    <....a.%.{...v.!
# 00000120: 3c01a000 0361d825 0360f809 00000000    <....a.%.`......
# 00000130: 3c1b8000 277b0030 0376d821 3c01a000    <...'{.0.v.!<...
# 00000140: 0361d825 8f7b000c 0376d821 3c01a000    .a.%.{...v.!<...
# 00000150: 0361d825 0360f809 00000000 041102f2    .a.%.`..........
# 00000160: 00000000 3c168000 26d60174 04110001    ....<...&..t....
# 00000170: 00000000 03f6b022 3c1b8000 277b0030    ......."<...'{.0
# 00000180: 0376d821 8f7b0040 0376d821 0360f809    .v.!.{.@.v.!.`..
# 00000190: 00000000 3c1b8000 277b0030 0376d821    ....<...'{.0.v.!
# 000001a0: 8f7b005c 0376d821 0360f809 00000000    .{.\.v.!.`......
# 000001b0: 14400009 00000000 00000000 3c1b8000    .@..........<...
# 000001c0: 277b0030 0376d821 8f7b0038 0376d821    '{.0.v.!.{.8.v.!
# 000001d0: 0360f809 00000000 00000000 3c048000    .`..........<...
# 000001e0: 24840d44 00962021 3c1b8000 277b0030    $..D.. !<...'{.0
# 000001f0: 0376d821 8f7b0048 0376d821 0360f809    .v.!.{.H.v.!.`..
# 00000200: 00000000 04110259 00000000 00000000    .......Y........
# 00000210: 3c044452 3484414d 3c1b8000 277b0030    <.DR4.AM<...'{.0
# 00000220: 0376d821 8f7b0004 0376d821 0360f809    .v.!.{...v.!.`..
# 00000230: 00000000 3c1b8000 277b0030 0376d821    ....<...'{.0.v.!
# 00000240: 8f7b0008 0376d821 0360f809 00000000    .{...v.!.`......
# 00000250: 00402021 3c1b8000 277b0030 0376d821    .@ !<...'{.0.v.!
# 00000260: 8f7b0020 0376d821 0360f809 00000000    .{. .v.!.`......
# 00000270: 3c1b8000 277b0030 0376d821 8f7b003c    <...'{.0.v.!.{.<
# 00000280: 0376d821 0360f809 00000000 0040d021    .v.!.`.......@.!
# 00000290: 1740000c 00000000 3c045241 34844d58    .@......<.RA4.MX
# 000002a0: 3c1b8000 277b0030 0376d821 8f7b0004    <...'{.0.v.!.{..
# 000002b0: 0376d821 0360f809 00000000 1000ffff    .v.!.`..........
# 000002c0: 00000000 24180100 031a082a 14200002    ....$......*. ..
# 000002d0: 00000000 0340c021 0018c500 241e0000    .....@.!....$...
# 000002e0: 24190000 3c048000 24840008 00962021    $...<...$..... !
# 000002f0: 8c9c0018 039ee020 3c045a42 34845353    ....... <.ZB4.SS
# 00000300: 3c1b8000 277b0030 0376d821 8f7b0004    <...'{.0.v.!.{..
# 00000310: 0376d821 0360f809 00000000 3c048000    .v.!.`......<...
# 00000320: 24840008 00962021 8c820014 8c83000c    $..... !........
# 00000330: 005e1020 007e1820 ac400000 ac400004    .^. .~. .@...@..
# 00000340: ac400008 ac40000c 20420010 0043082a    .@...@.. B...C.*
# 00000350: 1420fff9 00000000 3c04434f 34844445    . ......<.CO4.DE
# 00000360: 3c1b8000 277b0030 0376d821 8f7b0004    <...'{.0.v.!.{..
# 00000370: 0376d821 0360f809 00000000 3c048000    .v.!.`......<...
# 00000380: 24840008 00962021 8c890010 0120b821    $..... !..... .!
# 00000390: 8c8a0010 01565021 8c8b0000 01765821    .....VP!.....vX!
# 000003a0: 8d4c0000 8d4d0004 8d4e0008 8d4f000c    .L...M...N...O..
# 000003b0: ad2c0000 ad2d0004 ad2e0008 ad2f000c    .,...-......./..
# 000003c0: 21290010 214a0010 014b082b 1420fff4    !)..!J...K.+. ..
# 000003d0: 00000000 3c044441 34845441 3c1b8000    ....<.DA4.TA<...
# 000003e0: 277b0030 0376d821 8f7b0004 0376d821    '{.0.v.!.{...v.!
# 000003f0: 0360f809 00000000 3c048000 24840008    .`......<...$...
# 00000400: 00962021 8c890004 01364821 2408000f    .. !.....6H!$...
# 00000410: 01284820 01004027 01284824 8c8a0004    .(H ..@'.(H$....
# 00000420: 8c8b0008 015e5020 017e5820 8d2c0000    .....^P .~X .,..
# 00000430: 8d2d0004 8d2e0008 8d2f000c ad4c0000    .-......./...L..
# 00000440: ad4d0004 ad4e0008 ad4f000c 21290010    .M...N...O..!)..
# 00000450: 214a0010 014b082b 1420fff4 00000000    !J...K.+. ......
# 00000460: 10000148 00000000 00000000 00000000    ...H............
# 00000470: 00000000 00000000 00000000 00000000    ................
# 00000480: 00000000 00000000 00000000 00000000    ................
# 00000490: 00000000 00000000 00000000 00000000    ................
# 000004a0: 00000000 00000000 00000000 00000000    ................
# 000004b0: 00000000 00000000 00000000 00000000    ................
# 000004c0: 00000000 00000000 00000000 00000000    ................
# 000004d0: 00000000 00000000 00000000 00000000    ................
# 000004e0: 00000000 00000000 00000000 00000000    ................
# 000004f0: 00000000 00000000 00000000 00000000    ................
# 00000500: 00000000 00000000 00000000 00000000    ................
# 00000510: 00000000 00000000 00000000 00000000    ................
# 00000520: 00000000 00000000 00000000 00000000    ................
# 00000530: 00000000 00000000 00000000 00000000    ................
# 00000540: 00000000 00000000 00000000 00000000    ................
# 00000550: 00000000 00000000 00000000 00000000    ................
# 00000560: 00000000 00000000 00000000 00006600    ..............f.
# 00000570: 6366652d 76010026 76030000 00000000    cfe-v..&v.......
# 00000580: 00000006 653d3139 322e3136 382e312e    ....e=192.168.1.
# 00000590: 313a6666 66666666 30302068 3d313932    1:ffffff00 h=192
# 000005a0: 2e313638 2e312e31 30302067 3d20723d    .168.1.100 g= r=
# 000005b0: 6620663d 766d6c69 6e757820 693d6263    f f=vmlinux i=bc
# 000005c0: 6d393633 78785f66 735f6b65 726e656c    m963xx_fs_kernel
# 000005d0: 20643d31 20703d30 20633d20 613d20ff     d=1 p=0 c= a= .
# 000005e0: ffffffff ffffffff ffffffff ffffffff    ................
# 000005f0: ffffffff ffffffff ffffffff ffffffff    ................
# 00000600: ffffffff ffffffff ffffffff ffffffff    ................
# 00000610: ffffffff ffffffff ffffffff ffffffff    ................
# 00000620: ffffffff ffffffff ffffffff ffffffff    ................
# 00000630: ffffffff ffffffff ffffffff ffffffff    ................
# 00000640: ffffffff ffffffff ffffffff ffffffff    ................
# 00000650: ffffffff ffffffff ffffffff ffffffff    ................
# 00000660: ffffffff ffffffff ffffffff ffffffff    ................
# 00000670: ffffffff ffffffff ffffffff ffffffff    ................
# 00000680: ffffffff 39363331 36375245 46330000    ....963167REF3..
# 00000690: 00000000 00000000 00000018 00000010    ................
# 000006a0: 78810261 deadff00 ffffffff 00000000    x..a............
# 000006b0: 00000000 00000000 00000000 00000000    ................
# 000006c0: 00000000 ffffffff ffffffff ffffffff    ................
# 000006d0: ffffffff ffffffff ffffffff ffffffff    ................
# 000006e0: ffffffff ffffffff ffffffff ffffffff    ................
# 000006f0: ffffffff ffffffff ffffffff ffffffff    ................
# 00000700: ffffffff ffffffff ffffffff ffffffff    ................
# 00000710: ffffffff ffffffff ffffffff ffffffff    ................
# 00000720: ffffffff ffffffff ffffffff ffffffff    ................
# 00000730: ffffffff ffffffff ffffffff ffffffff    ................
# 00000740: ffffffff ffffffff ffffffff ffffffff    ................
# 00000750: ffffffff ffffffff ffffffff ffffffff    ................
# 00000760: ffffffff ffffffff ffffffff ffffffff    ................
# 00000770: ffffffff ffffffff ffffffff ffffffff    ................
# 00000780: ffffffff ffffffff ffffffff ffffffff    ................
# 00000790: ffffffff ffffffff ffffffff ffffffff    ................
# 000007a0: ffffffff ffffffff ffffffff ffffffff    ................
# 000007b0: ffffffff ffffffff ffffffff ffffffff    ................
# 000007c0: ffffffff ffffffff ffffff00 00000000    ................
# 000007d0: 00000000 00000080 0000f600 0001ec00    ................
# 000007e0: 0001fc00 00000080 0000f580 0000f580    ................
# 000007f0: 00001000 00000400 4c453936 37325f5a    ........LE9672_Z
# 
# ----------- spare area for block 0, page 0 -----------
# 00000800: ff198520 03000000 080a18d8 7a75874a    ... ........zu.J
# 00000810: ffffffff ffffffff ff0b4028 13dc2db8    ..........@(..-.
# 00000820: ffffffff ffffffff ff0e4785 37c474e0    ..........G.7.t.
# 00000830: ffffffff ffffffff ff0c332c 4063cef7    ..........3,@c..
# 
# *** command status = 1
# CFE>

import argparse
import re
import sys
import time
import traceback
from typing import Generator, TextIO

import serial

MAX_RETRIES = 5
NAND_SIZE = 131072 * 1024 # 128MiB
BLOCK_SIZE = 128 * 1024
PAGE_SIZE = 2048

line_regex = re.compile(r'(?P<addr>[0-9a-fA-F]{8}):(?P<data>(?: [0-9a-fA-F]{8}){4})(?:\s+.{16})?')
#Correctable ECC Error detected: addr=0x00203600, intrCtrl=0x00000090, accessCtrl=0xE3441010

def parse_hex_byte_string(hexbytes: str) -> bytes:
    assert len(hexbytes) % 2 == 0
    return int(hexbytes, 16).to_bytes(len(hexbytes) // 2, 'big')


def parse_serial_line(line: str) -> Generator[bytes, None, None]:
    m = line_regex.match(line)

    try:
        for chunk in m.group('data').split():
            yield parse_hex_byte_string(chunk)
    except Exception:
        print("\n\nError caused by line: '{}'".format(line))
        raise


def format_size(size: int) -> str:
    units = ('', 'K', 'M', 'G', 'T')
    count = 0

    while size > 1500:
        size /= 1024
        count += 1

    return "{}{}B".format(round(size, 1), units[count])


def format_time(time: int) -> str:
    if time < 60:
        return "{}s".format(time)

    s = time % 60
    time //= 60
    if time < 60:
        return "{}m {}s".format(time, s)

    m = time % 60
    time //= 60
    if time < 24:
        return "{}h {}m {}s".format(time, m, s)

    h = time % 24
    time //= 24
    return "{}d {}h {}m {}s".format(time, h, m, s)


class PrettyPrinter:
    def __init__(self, out: TextIO):
        self.out = out
        self._lastline_len = 0

    def clear_line(self):
        print('\r' + ' ' * self._lastline_len, file=self.out)

    def print(self, string):
        if len(string) > 100000:
            print(string, file=self.out, end='')
        else:
            lines = string.split("\n")
            self._lastline_len = len(lines[-1])

            for l in lines[:-1]:
                print(string, file=self.out)

            if lines[-1] != '':
                print(string, file=self.out, end='')

        self.out.flush()

    def msg(self, string):
        self.clear_line()
        self.print(string)
        print('\n\n', end='', file=self.out)

    def error(self, msg):
        self.msg(msg)

    def exc(self):
        string = traceback.format_exc()
        self.error(string)


class ProgressPrinter(PrettyPrinter):
    chars = "⡏⠟⠻⢹⣸⣴⣦⣇"

    def __init__(self, out: TextIO, item_size: int, item_name: str):
        super().__init__(out)
        self.item_size = item_size
        self.item_name = item_name
        self._chars_step = 0
        self._last_done = -1
        self._last_total = -1
        self._clean = True
        self._last_time = -1

    def clear_line(self):
        super().clear_line()
        self._clean = True

    def print_progress(self, done, total):
        if self._last_total != total:
            self.clear_line()

        string = "\r {} ".format(self.chars[self._chars_step])

        string += "[{}/{} {}] ".format(done, total, self.item_name)
        string += "[{}/{}] ".format(format_size(done * self.item_size), format_size(total * self.item_size))

        if self._last_time > 0:
            delta_t = time.time() - self._last_time
            delta_b = done - self._last_done
            speed = delta_b / delta_t

            string += "[{}/s] ".format(format_size(speed))

            remaining = total - done
            try:
                eta = int(remaining // speed)
            except ZeroDivisionError:
                eta = int(0)

            string += "[ETA: {}]".format(format_time(eta))

        self._chars_step = (self._chars_step + 1) % len(self.chars)
        self._last_done = done
        self._last_total = total
        self._last_time = time.time()

        self.print(string)


class CFECommunicator:
    # noinspection PyShadowingNames
    def __init__(self, serial: serial.Serial, block_size: int = BLOCK_SIZE, page_size: int = PAGE_SIZE,
                 nand_size: int = NAND_SIZE, max_retries: int = MAX_RETRIES, printer: PrettyPrinter = None):
        self.max_retries = max_retries
        self.block_size = block_size
        self.page_size = page_size
        self.nand_size = nand_size
        self.ser = serial
        self.printer = printer or PrettyPrinter(sys.stdout)

    def eat_junk(self) -> None:
        while self.ser.read(1):
            pass

    def wait_for_prompt(self) -> None:
        self.printer.msg("Waiting for a prompt...")
        while True:
            self.ser.write(b"\r\n")
            if self.ser.read(1) == b'C' and self.ser.read(1) == b'F' \
                    and self.ser.read(1) == b'E' and self.ser.read(1) == b'>':
                self.eat_junk()
                return

    def parse_pages_bulk(self) -> Generator[bytes, None, None]:
        while not self.ser.readline().startswith(b"-----"):
            pass
        buf = b''

        while True:
            line = self.ser.readline().strip()

            if len(line) == 0:
                continue

            # Spare area. Yield and skip to next page
            if line.startswith(b"-----"):
                yield buf
                buf = b''

                while not self.ser.readline().startswith(b"-----"):
                    pass
                continue

            try:
                for b in parse_serial_line(line.decode()):
                    buf += b
            except UnicodeDecodeError:
                traceback.print_exc()

    def read_page(self, block: int, page: int) -> bytes:
        buf = b''
        main_area_read = False

        self.ser.write("dn {block} {page} 1\r\n".format(block=block, page=page).encode())
        self.ser.readline()  # remove echo

        while True:
            line = self.ser.readline().strip()

            if line.startswith(b"-----"):
                if main_area_read:
                    break
                main_area_read = True
                continue

#danitool begin: eat crashing line
            if line.startswith(b"Correctable ECC Error detected"):
                continue
#danitool end

            if len(line) == 0:
                continue

            try:
                for b in parse_serial_line(line.decode()):
                    buf += b
            except UnicodeDecodeError:
                traceback.print_exc()

        if len(buf) != self.page_size:
            raise IOError("Read page size ({}) different from expected size ({})"
                          .format(len(buf), self.page_size))

        self.eat_junk()

        return buf

    def read_pages(self, block: int, page_start: int, number: int) -> Generator[bytes, None, None]:
        for page in range(page_start, page_start + number):
            retries = 0

            while retries < self.max_retries:
                try:
                    yield self.read_page(block, page)
                    break
                except Exception:
                    print("Block {} page {} read failed, retrying.".format(block, page))
                    retries += 1
                    self.printer.exc()
            else:
                raise IOError("Max number of page read retries exceeded")

    def read_pages_bulk(self, block: int, page_start: int, number: int) -> Generator[bytes, None, None]:
        self.ser.write("dn {block} {page} {number}\r\n".format(block=block, page=page_start, number=number).encode())
        yield from self.parse_pages_bulk()

    def read_block(self, block: int) -> Generator[bytes, None, None]:
        count = 0
        for i in self.read_pages(block, 0, self.block_size // self.page_size):
            yield i
            count += 1

        expected = self.block_size // self.page_size
        if count != expected:
            raise IOError("Read block size ({}) different from expected size ({})"
                          .format(count, expected))

    def read_blocks(self, block: int, number: int) -> Generator[bytes, None, None]:
        for block in range(block, block + number):
            yield from self.read_block(block)

    def read_nand(self) -> Generator[bytes, None, None]:
        for block in range(self.nand_size // self.block_size):
            yield from self.read_block(block)

    def read_nand_bulk(self) -> Generator[bytes, None, None]:
        yield from self.read_pages_bulk(0, 0, self.nand_size // self.page_size)


def main():
    parser = argparse.ArgumentParser(description="Broadcom CFE dumper")
    parser.add_argument('-N', '--nand-size', type=int, help="NAND size", default=NAND_SIZE)
    parser.add_argument('-B', '--block-size', type=int, help="Block size", default=BLOCK_SIZE)
    parser.add_argument('-P', '--page-size', type=int, help="Page size", default=PAGE_SIZE)
    parser.add_argument('-D', '--device', type=str, help="Serial port", required=True)
    parser.add_argument('-b', '--baudrate', type=str, help="Baud rate", default=115200)
    parser.add_argument('-t', '--timeout', type=float, help="Serial port timeout", default=0.1)
    parser.add_argument('-O', '--output', type=str, help="Output file, '-' for stdout", default='-')
    parser.add_argument('-r', '--max-retries', type=int, help="Max retries per page on failure", default=MAX_RETRIES)

    subparsers = parser.add_subparsers(help="Available commands", dest='command')

    readpage_parser = subparsers.add_parser('page', help="Read one or more pages")
    readpage_parser.add_argument('block', type=int, help="Block to read pages from")
    readpage_parser.add_argument('page', type=int, help="Page to read")
    readpage_parser.add_argument('number', type=int, help="Number of subsequent pages to read (if more than 1)",
                                 default=1)

    readpage_parser = subparsers.add_parser('pages_bulk', help="Read one or more pages in bulk")
    readpage_parser.add_argument('block', type=int, help="Block to read pages from")
    readpage_parser.add_argument('page', type=int, help="Page to read")
    readpage_parser.add_argument('number', type=int, help="Number of subsequent pages to read (if more than 1)",
                                 default=1)

    readblock_parser = subparsers.add_parser('block', help="Read one or more blocks")
    readblock_parser.add_argument('block', type=int, help="Block to read")
    readblock_parser.add_argument('number', type=int, help="Number of subsequent blocks to read (if more than 1)",
                                  default=1)

    subparsers.add_parser('nand', help="Read the entire NAND")
    subparsers.add_parser('nand_bulk', help="Read the entire NAND in bulk")

    args = parser.parse_args()
    printer = ProgressPrinter(sys.stdout if args.output != "-" else sys.stderr, args.page_size, "pages")
    ser = serial.Serial(args.device, args.baudrate, timeout=args.timeout)
    c = CFECommunicator(ser, args.block_size, args.page_size, args.nand_size, args.max_retries, printer)

    if args.command == 'page':
        gen = c.read_pages(args.block, args.page, args.number)
        pages = args.number
    elif args.command == 'pages_bulk':
        gen = c.read_pages_bulk(args.block, args.page, args.number)
        pages = args.number
    elif args.command == 'block':
        gen = c.read_blocks(args.block, args.number)
        pages = args.block_size // args.page_size * args.number
    elif args.command == 'nand':
        gen = c.read_nand()
        pages = args.nand_size // args.page_size
    elif args.command == 'nand_bulk':
        gen = c.read_nand_bulk()
        pages = args.nand_size // args.page_size
    else:
        raise RuntimeError

    pages_read = 0

    c.wait_for_prompt()

    with open(args.output, 'wb') as output:
        try:
            for page in gen:
                pages_read += 1
                output.write(page)
                if type(c) == CFECommunicator or pages_read % 100 == 0:
                    printer.print_progress(pages_read, pages)
        except Exception:
            printer.print_progress(pages_read, pages)
            raise

    printer.print("\n\n")


if __name__ == "__main__":
    main()
