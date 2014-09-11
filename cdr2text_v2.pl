#!/usr/bin/perl
#
# The script converts a binary-encoded log file into RDBMS-friendly
# text.  It expects to receive the binary log file via STDIN
#
# August 2014 - Created by Saurav Dhungana, Oval Analytics Pvt. Ltd.


## Load Required Modules
use warnings;

use Time::Piece;

## Turn Debug Text On or Off
$Verbose = 0;
#$Verbose = 1;

# Only add header row once
$CSV_Header = 1;

#
# Lookup tables for enumerated values
#

my %OpProp_lookup = (
  '0', 'S',
  '1', '',
  '2', 'N',
  '3', 'I'
);

my %RecType_lookup = (
  '1', 'PSTN',
  '2', '',
  '3', 'IN',
  '4', 'ISDN',
  '5', '',
  '6', '',
  '7', '',
  '8', 'CGAS',
  '9', 'MCU/Video Conference'
);

my %PartRecID_lookup = (
  '0', 'Single',
  '1', 'First Part',
  '2', 'Interim Part',
  '3', 'Final Part'
);


my %EndReason_lookup = (
  '0', 'By Calling Party',
  '1', 'By Called Party Number',
  '2', 'Abnormal Hook On',
  '3', ''
);

my %OpType_lookup = (
  '00', 'Calling party, category is unknown',
  '01', 'Operator, language French',
  '02', 'Operator, language English',
  '03', 'Operator, language German',
  '04', 'Operator, language Russian',
  '05', 'Operator, language Spanish',
  '06', 'Operator, Consultation Language (Chinese) Language (Chinese)',
  '07', 'Operator, Consultation Language',
  '08', 'Operator, Consultation Language (Japanese)',
  '09', 'National Operator',
  '0a', 'Ordinary calling subscriber',
  '0b', 'Calling subscriber with priority',
  '0c', 'Data Call (voice band data)',
  '0d', 'Test call',
  '0e', '',
  '0f', '',
  '10-bf', '',
  'e0-ef', '',
  'e1-ef', 'Spare for National',
  'f0', 'Ordinary calling subscriber, Free',
  'f1', 'Ordinary calling subscriber, Periodic',
  'f2', 'Ordinary calling subscriber, immediate',
  'f3', 'Ordinary Printer, immediate',
  'f4', 'Calling subscriber with priority, Free',
  'f5', 'Calling subscriber with priority, Periodic',
  'f8', 'Ordinary (City - City)'
);

my %InMGType_lookup = (
  '1', 'DEVTYPE_NAS',
  '2', 'DEVTYPE_TG',
  '3', 'DEVTYPE_AG',
  '4', 'DEVTYPE_IPPBX',
  '5', 'DEVTYPE_MSAG',
  '6', 'DEVTYPE_IAD',
  '7', 'DEVTYPE_WAG',
  '8', 'DEVTYPE_H323GW',
  '9', 'DEVTYPE_SG',
  '10', 'DEVTYPE_OTHSS',
  '11', 'DEVTYPE_AS',
  '12', 'DEVTYPE_SIP',
  '13', 'DEVTYPE_H323',
  '14', 'DEVTYPE_H323GK',
  '15', 'DEVTYPE_H323IAD',
  '16', 'DEVTYPE_BICC',
  '17', 'DEVTYPE_MSG',
  '18', 'DEVTYPE_BIGCTX',
  '19', 'DEVTYPE_CSCF'
);

my %bOpProtocol_lookup = (
  '1', 'MGCP',
  '2', 'H.248',
  '3', 'H.323',
  '6', 'SIP'
);

my %bCallDirect_lookup = (
  '0', 'IAD-IAD',
  '1', 'IAd-Trunk',
  '2', 'IAD-IP',
  '3', 'Trunk-IAD',
  '4', 'Trunk-Trunk',
  '5', 'Trunk-IP',
  '6', 'IP-IAD',
  '7', 'IP-Trunk',
  '8', 'IP-IP',
  # For Fail call CDR, the caller can not know the callee type, then
  '251', 'Caller is Local User',
  '252', 'Caller is incoming trunk',
  '253', 'Caller is IP',
  '254', 'Caller is Unknown'
);

my %bCallType_lookup = (
  '0', 'Voice',
  '1', 'FAX',
  '2', 'Data',
  '3', 'Reserved',
  '4', 'Video'
);

my %bOpCoding_lookup = (
  '0', 'B_AUDIO_CODETYPE_UNKNOWN',
  '1', 'B_AUDIO_CODETYPE_G711A',
  '2', 'B_AUDIO_CODETYPE_G729',
  '3', 'B_AUDIO_CODETYPE_G723',
  '4', 'B_AUDIO_CODETYPE_G711',
  '5', 'B_AUDIO_CODETYPE_G728',
  '6', 'B_AUDIO_CODETYPE_G722',
  '7', 'B_AUDIO_CODETYPE_G726',
  '10', 'B_VIDEO_CODETYPE_UNKNOWN',
  '11', 'B_VIDEO_CODETYPE_H261',
  '12', 'B_VIDEO_CODETYPE_H263',
  '13', 'B_VIDEO_CODETYPE_H263PLUS',
  '14', 'B_VIDEO_CODETYPE_H263PLUSPLUS',
  '15', 'B_VIDEO_CODETYPE_H264',
  '16', 'B_VIDEO_CODETYPE_MPEG2',
  '17', 'B_VIDEO_CODETYPE_MPEG4'
);

my %BillNoProp_lookup = (
  '0', 'S',
  '1', '',
  '2', 'N',
  '3', 'I',
  '4', 'Card A',
  '5', 'Card B',
  '6', 'Card C',
  '7', 'Card D',
  '8', 'Visa Card',
  '9', 'VPN Group Number',
  '10', 'VPN Extension Number'
);


my %ChgModulatorType_lookup = (
  '1', 'Fee Rate',
  '2', 'Total Fee'
);

my %InAttachFeeKind_lookup = (
  '1', 'Accessory Fee',
  '2', 'Accessory Fee Rate'
);

my %ServiceCategory_lookup = (
  '0', 'Vacant Number',
  '1', 'Local(same office code)',
  '2', 'Local(same area code and different office code in metro)',
  '3', 'Local(Suburban)',
  '4', 'National Manual Toll(intraregional)',
  '5', 'National Automatic Toll(intraregional)',
  '6', 'National Manual Toll(interregional)',
  '7', 'National Automatic Toll(interregional)',
  '8', 'International Manual Toll',
  '9', 'International Automatic Toll',
  '10', 'Charged Special Service',
  '11', 'Free Special Service',
  '12', 'Supplement Service',
  '13', 'Inside Centrex',
  '14', 'Outside Centrex',
  '15', 'IN Service',
  '16', 'URL Service',
  '17', 'IP Service'
);

my %CallDirection_lookup = (
  '0', 'SS inner call',
  '1', 'Outgoing SS by Trunk',
  '2', 'Outgoing SS by IP'
);

## Sub-Routines go here
# Sub routine to clean up BCD encoded data
sub clean_bcd {
  my $s = shift;
  $s =~ s/0//g;
  $s =~ s/a|A/0/g;
  $s =~ s/b|B/*/g;
  $s =~ s/c|C/#/g;

  if (defined($s) && $s ne "") {
    # input is defined and not empty
    return $s;
  }
  else {
    return 0;
  }

}

sub decode_timestamp {
   my ($seconds, $ms) = unpack("N C", pack("H10", shift));
   #print $seconds, "seconds ", $ms, "ms\n";
   if ($seconds > 0){
   my $base = Time::Piece->strptime('2000-01-01', '%Y-%m-%d');
   ($base + $seconds)->strftime('%Y-%m-%d %H:%M:%S') . sprintf '.%02d', $ms;
    } else {
        return 0;
    }

}

sub decode_ipaddress {
   my ($first, $second, $third, $fourth) = unpack("C C C C", pack("H8", shift));

   return sprintf("%u.%u.%u.%u", $first, $second, $third, $fourth)
}



# Start Main Code

use open ':encoding(utf8)';

#
# Interpret any command line args as a call for help
#
if ($ARGV[0]) {
  print STDOUT "cdr2text.pl usage: 'cat  | cdr2text.pl'\n";
  exit 0;
}

# Open STDIN
open(FILE, "-") or die "cannot open STDIN: $!";

binmode(FILE);

my $recordcount=0;      # Keep track of the number of records processed

###############
# Step 1 - Pull in the raw data, 1 record at a time.
# Assign the values to a 'raw' hash
# Assume each record is 559 bytes long...
###############
while (read(FILE, $buff, 559)) {
  %raw = ();        # Hash for first-pass extractions
  %clean = ();      # Hash for cleaned up values, for output

  #
  # Use 'unpack' to extract all fields.  Some fields will need
  # further processing, which will be handled later.
  # Prepend fieldnames with the CDR field number
  #

  (
    $raw{'01_BillVersion'},
    $raw{'02_SSID'},
    $raw{'03_BillID'},
    $raw{'04_RecType'},
    $raw{'05_PartRecID'},
    $raw{'06_SeqNum'},
    $raw{'07_OpProp'},
    $raw{'08_OpNo'},
    $raw{'09_OpNet'},
    $raw{'10a_OpLata'},
    $raw{'10b_OpLata'},
    $raw{'11_OutpOpProp'},
    $raw{'12_OutpOpNo'},
    $raw{'13_OutpOpNet'},
    $raw{'14a_OutpOpLata'},
    $raw{'14b_OutpOpLata'},
    $raw{'15_DialedNoProp'},
    $raw{'16_DialedNo'},
    $raw{'17_DialedNet'},
    $raw{'18a_DialedLata'},
    $raw{'18b_DialedLata'},
    $raw{'19_DialTpNoPrefixLen'},
    $raw{'20_TpProp'},
    $raw{'21_TpNo'},
    $raw{'22_TpNet'},
    $raw{'23a_TpLata'},
    $raw{'23b_TpLata'},
    $raw{'24_TpNoPrefixLen'},
    $raw{'25_OutpTpProp'},
    $raw{'26_OutpTpNo'},
    $raw{'27_OutpTpNet'},
    $raw{'28a_OutpTpLata'},
    $raw{'28b_OutpTpLata'},
    $raw{'29_OutpTpNoPrefixLen'},
    $raw{'30_AnswerTime'},
    $raw{'31x_ServiceCat'},
    $raw{'32_EndTime'},
    $raw{'33_EndReason'},
    $raw{'34_OpType'},
    $raw{'35x_IDString'},    # Note: This goes from 35 - 42. Data on each bit.
    $raw{'43_InTrkGrpType'},
    $raw{'44_InTrkGrpNo'},
    $raw{'45_InTrkCircuitNo'},
    $raw{'46_InTrkConnectTime'},
    $raw{'47_InTrkDisconnectTime'},
    $raw{'48_IngressOPC'},
    $raw{'49_IngressDPC'},
    $raw{'50_InMGType'},
    $raw{'51_InMGID'},
    $raw{'52_bOpSSIPAddr'},
    $raw{'53_bOpMGIPAddr'},
    $raw{'54_bOpRtpIPAddr'},
    $raw{'55_bOpProtocol'},
    $raw{'56_bCallDirect'},
    $raw{'57_bCallType'},
    $raw{'58_bOpCoding'},
    $raw{'59_bCallParty'},
    $raw{'60_OutTrkGrpType'},
    $raw{'61_OutTrkGrpNo'},
    $raw{'62_OutTrkCircuitNo'},
    $raw{'63_OutTrkConnectTime'},
    $raw{'64_OutTrkDisconnectTime'},
    $raw{'65_EgressOPC'},
    $raw{'66_EgressDPC'},
    $raw{'67_OutMGType'},
    $raw{'68_OutMGID'},
    $raw{'69_bTpSSIPAddr'},
    $raw{'70_bTpMGIPAddr'},
    $raw{'71_bTpRtpIPAddr'},
    $raw{'72_bTpProtocol'},
    $raw{'73_dwFaxPage'},
    $raw{'74_SS'},
    $raw{'75_ChargeID'},
    $raw{'76_LinkProp'},
    $raw{'77_LinkNo'},
    $raw{'78_LinkNet'},
    $raw{'79a_LinkLata'},
    $raw{'79b_LinkLata'},
    $raw{'80_Fee'},
    $raw{'81_CustomerID'},
    $raw{'82_CustLocationID'},
    $raw{'83_AccountCodeType'},
    $raw{'84_AccountCode'},
    $raw{'85_AccessNumber'},
    $raw{'86_CarrierID'},
    $raw{'87_OpCtxNo'},
    $raw{'88_TpCtxNo'},
    $raw{'89_IngresBytes'},
    $raw{'90_EgressBytes'},
    $raw{'91_AuthorityType'},
    $raw{'92_Filler1'},
    $raw{'93_Filler2'},
    $raw{'94_AuthorityCode'},
    $raw{'95_CarrierSelectInfo'},
    $raw{'96_BearerSvc'},
    $raw{'97_TeleSvc'},
    $raw{'98_USS1'},
    $raw{'99_USS3'},
    $raw{'x100_SpOpNo'},                # Prefix 'x' added as a hack to maintain field order (numeric)
    $raw{'x101_SpTpNo'},
    $raw{'x102_BillNoProp'},
    $raw{'x103_BillNo'},
    $raw{'x104_BillNet'},
    $raw{'x105a_BillLata'},
    $raw{'x105b_BillLata'},
    $raw{'x106_TransNoProp'},
    $raw{'x107_TransNo'},
    $raw{'x108_TransNet'},
    $raw{'x109a_TransLata'},
    $raw{'x109b_TransLata'},
    $raw{'x110_LocNoProp'},
    $raw{'x111_LocNo'},
    $raw{'x112_LocNet'},
    $raw{'x113a_LocLata'},
    $raw{'x113b_LocLata'},
    $raw{'x114a_ChgRateKind'},
    $raw{'x114b_ChgRateKind'},
    $raw{'x115_ChgModulatorType'},
    $raw{'x116_ChgModulatorVal'},
    $raw{'x117_InAttachFeeKind'},
    $raw{'x118_InAttachFeeVal'},
    $raw{'x119_TransparentParameter'}

  ) = unpack('
    H4                      # 01_BillVersion
    H4                      # 02_SSID
    H8                      # 03_BillID
    H2                      # 04_RecType
    H2                      # 05_PartRecID
    H4                      # 06_SeqNum
    H2                      # 07_OpProp
    H64                     # 08_OpNo
    H2                      # 09_OpNet
    H2 H2                   # 10_OpLata
    H2                      # 11_OutpOpProp
    H64                     # 12_OutpOpNo
    H2                      # 13_OutpOpNet
    H2 H2                   # 14_OutpOpLata
    H2                      # 15_DialedNoProp
    H64                     # 16_DialedNo
    H2                      # 17_DialedNet
    H2 H2                   # 18_DialedLata
    H2                      # 19_DialTpNoPrefixLen
    H2                      # 20_TpProp
    H64                     # 21_TpNo
    H2                      # 22_TpNet
    H2 H2                   # 23_TpLata
    H2                      # 24_TpNoPrefixLen
    H2                      # 25_OutpTpProp
    H64                     # 26_OutpTpNo
    H2                      # 27_OutpTpNet
    H2 H2                   # 28_OutpTpLata
    H2                      # 29_OutpTpNoPrefixLen
    H10                     # 30_AnswerTime
    H2                      # 31x_ServiceCat
    H10                     # 32_EndTime
    H2                      # 33_EndReason
    H2                      # 34_OpType
    H2                      # 35x_IDString
    H2                      # 43_InTrkGrpType
    H4                      # 44_InTrkGrpNo
    H4                      # 45_InTrkCircuitNo
    H10                     # 46_InTrkConnectTime
    H10                     # 47_InTrkDisconnectTime
    H6                      # 48_IngressOPC
    H6                      # 49_IngressDPC
    H2                      # 50_InMGType
    H4                      # 51_InMGID
    H8                      # 52_bOpSSIPAddr
    H8                      # 53_bOpMGIPAddr
    H8                      # 54_bOpRtpIPAddr
    H2                      # 55_bOpProtocol
    H2                      # 56_bCallDirect
    H2                      # 57_bCallType
    H2                      # 58_bOpCoding
    H2                      # 59_bCallParty
    H2                      # 60_OutTrkGrpType
    H4                      # 61_OutTrkGrpNo
    H4                      # 62_OutTrkCircuitNo
    H10                     # 63_OutTrkConnectTime
    H10                     # 64_OutTrkDisconnectTime
    H6                      # 65_EgressOPC
    H6                      # 66_EgressDPC
    H2                      # 67_OutMGType
    H4                      # 68_OutMGID
    H8                      # 69_bTpSSIPAddr
    H8                      # 70_bTpMGIPAddr
    H8                      # 71_bTpRtpIPAddr
    H2                      # 72_bTpProtocol
    H8                      # 73_dwFaxPage
    H14                     # 74_SS
    H2                      # 75_ChargeID
    H2                      # 76_OutpTpProp
    H64                     # 77_OutpTpNo
    H2                      # 78_OutpTpNet
    H2 H2                   # 79_OutpTpLata
    H8                      # 80_Fee
    H8                      # 81_CustomerID
    H8                      # 82_CustLocationID
    H2                      # 83_AccountCodeType
    H20                     # 84_AccountCode
    H8                      # 85_AccessNumber
    H4                      # 86_CarrierID
    H4                      # 87_OpCtxNo
    H4                      # 88_TpCtxNo
    H16                     # 89_IngresBytes
    H16                     # 90_EgressBytes
    H2                      # 91_AuthorityType
    H8                      # 92_Filler1
    H2                      # 93_Filler2
    H32                     # 94_AuthorityCode
    H4                      # 95_CarrierSelectInfo
    H2                      # 96_BearerSvc
    H2                      # 97_TeleSvc
    H2                      # 98_USS1
    H2                      # 99_USS3
    H10                     # x100_SpOpNo
    H10                     # x101_SpTpNo
    H2                      # x102_BillNoProp
    H64                     # x103_BillNo
    H2                      # x104_BillNet
    H2 H2                   # x105_BillLata
    H2                      # x106_TransNoProp
    H64                     # x107_TransNo
    H2                      # x108_TransNet
    H2 H2                   # x109_TransLata
    H2                      # x110_LocNoProp
    H64                     # x111_LocNo
    H2                      # x112_LocNet
    H2 H2                   # x113_LocLata
    H2 H2                   # x114_ChgRateKind
    H2                      # x115_ChgModulatorType
    H2                      # x116_ChgModulatorVal
    H2                      # x117_InAttachFeeKind
    H8                      # x118_InAttachFeeVal
    H40                     # x119_TransparentParameter
  h*', $buff);


  ###############
  # Step 2 - Clean up fields, make them readable.
  # Put the translated values into the 'clean' hash
  ###############

  # 01_BillVersion
  $clean{'01_BillVersion'} = unpack("n",
                               pack("H4", $raw{'01_BillVersion'}));

  # 02_SSID
  $clean{'02_SSID'} = unpack("n",
                             pack("H4", $raw{'02_SSID'}));

  # 03_BillID
  $clean{'03_BillID'} = unpack("N",
                           pack("H8", $raw{'03_BillID'}));

  # 04_RecType
  $tmp = unpack("I", pack("H8", $raw{'04_RecType'}));
  if (exists $RecType_lookup{$tmp}) {
    $clean{'04_RecType'} = $RecType_lookup{$tmp};
  } else {
    $clean{'04_RecType'} = "U";
  }

  # 05_PartRecID
  $tmp = unpack("I", pack("H8", $raw{'05_PartRecID'}));
  if (exists $PartRecID_lookup{$tmp}) {
    $clean{'05_PartRecID'} = $PartRecID_lookup{$tmp};
  } else {
    $clean{'05_PartRecID'} = "U";
  }

  # 06_SeqNum
  $clean{'06_SeqNum'} = unpack("N",
                       pack("H8", $raw{'06_SeqNum'}));

  # 07_OpProp
  $tmp = unpack("I", pack("H8", $raw{'07_OpProp'}));
  if (exists $OpProp_lookup{$tmp}) {
    $clean{'07_OpProp'} = $OpProp_lookup{$tmp};
  } else {
    $clean{'07_OpProp'} = "U";
  }

 # 08_OpNo
  $tmp = unpack("H64", pack("h64", $raw{'08_OpNo'}));
  $clean{'08_OpNo'} = clean_bcd($tmp);

  # 09_OpNet
  $clean{'09_OpNet'} = unpack("I",
                     pack("H8", $raw{'09_OpNet'}));

  # 10_OpLata
  $tmp = unpack("H4",
         pack("h2 h2",
              $raw{'10b_OpLata'},
              $raw{'10a_OpLata'}));
  $clean{'10_OpLata'} = clean_bcd($tmp);

  # 11_OutpOpProp
  $tmp = unpack("I", pack("H8", $raw{'11_OutpOpProp'}));
  if (exists $OpProp_lookup{$tmp}) {
    $clean{'11_OutpOpProp'} = $OpProp_lookup{$tmp};
  } else {
    $clean{'11_OutpOpProp'} = "U";
  }

  # 12_OutpOpNo
  $tmp = unpack("H64", pack("h64", $raw{'12_OutpOpNo'}));
  $clean{'12_OutpOpNo'} = clean_bcd($tmp);

  # 13_OutpOpNet
  $clean{'13_OutpOpNet'} = unpack("I",
                     pack("H8", $raw{'13_OutpOpNet'}));

  # 14_OutpOpLata
  $tmp = unpack("H4",
         pack("h2 h2",
              $raw{'14b_OutpOpLata'},
              $raw{'14a_OutpOpLata'}));
  $clean{'14_OutpOpLata'} = clean_bcd($tmp);

  # 15_DialedNoProp
  $tmp = unpack("I", pack("H8", $raw{'15_DialedNoProp'}));
  if (exists $OpProp_lookup{$tmp}) {
    $clean{'15_DialedNoProp'} = $OpProp_lookup{$tmp};
  } else {
    $clean{'15_DialedNoProp'} = "U";
  }

  # 16_DialedNo
  $tmp = unpack("H64", pack("h64", $raw{'16_DialedNo'}));
  $clean{'16_DialedNo'} = clean_bcd($tmp);

  # 17_DialedNet
  $clean{'17_DialedNet'} = unpack("I",
                     pack("H8", $raw{'17_DialedNet'}));

  # 18_DialedLata
  $tmp = unpack("H4",
         pack("h2 h2",
              $raw{'18b_DialedLata'},
              $raw{'18a_DialedLata'}));
  $clean{'18_DialedLata'} = clean_bcd($tmp);

  # 19_DialTpNoPrefixLen
  $clean{'19_DialTpNoPrefixLen'} = unpack("I",
                   pack("H8", $raw{'19_DialTpNoPrefixLen'}));

  # 20_TpProp
  $tmp = unpack("I", pack("H8", $raw{'20_TpProp'}));
  if (exists $OpProp_lookup{$tmp}) {
    $clean{'20_TpProp'} = $OpProp_lookup{$tmp};
  } else {
    $clean{'20_TpProp'} = "U";
  }

  # 21_TpNo
  $tmp = unpack("H64", pack("h64", $raw{'21_TpNo'}));
  $clean{'21_TpNo'} = clean_bcd($tmp);

  # 22_TpNet
  $clean{'22_TpNet'} = unpack("I",
                     pack("H8", $raw{'22_TpNet'}));

  # 23_TpLata
  $tmp = unpack("H4",
         pack("h2 h2",
              $raw{'23b_TpLata'},
              $raw{'23a_TpLata'}));
  $clean{'23_TpLata'} = clean_bcd($tmp);

  # 24_TpNoPrefixLen
  $clean{'24_TpNoPrefixLen'} = unpack("I",
                   pack("H8", $raw{'24_TpNoPrefixLen'}));

  # 25_OutpTpProp
  $tmp = unpack("I", pack("H8", $raw{'25_OutpTpProp'}));
  if (exists $OpProp_lookup{$tmp}) {
    $clean{'25_OutpTpProp'} = $OpProp_lookup{$tmp};
  } else {
    $clean{'25_OutpTpProp'} = "U";
  }

  # 26_OutpTpNo
  $tmp = unpack("H64", pack("h64", $raw{'26_OutpTpNo'}));
  $clean{'26_OutpTpNo'} = clean_bcd($tmp);

  # 27_OutpTpNet
  $clean{'27_OutpTpNet'} = unpack("I",
                     pack("H8", $raw{'27_OutpTpNet'}));

  # 28_OutpTpLata
  $tmp = unpack("H4",
         pack("h2 h2",
              $raw{'28b_OutpTpLata'},
              $raw{'28a_OutpTpLata'}));
  $clean{'28_OutpTpLata'} = clean_bcd($tmp);

  # 29_OutpTpNoPrefixLen
  $clean{'29_OutpTpNoPrefixLen'} = unpack("I",
                   pack("H8", $raw{'29_OutpTpNoPrefixLen'}));

  # 30_AnswerTime
  $clean{'30_AnswerTime'} = decode_timestamp($raw{'30_AnswerTime'});

  # 31_ServiceCat
  #$clean{'31x_ServiceCatRaw'} = unpack("B*", pack("H*", $raw{'31x_ServiceCat'}));

  $tmp1 = unpack("C", pack("H8", $raw{'31x_ServiceCat'})) & 0x1f;
  #print $tmp1, "\n";

  if (exists $ServiceCategory_lookup{$tmp1}) {
    $clean{'31a_ServiceCategory'} = $ServiceCategory_lookup{$tmp1};
  } else {
    $clean{'31a_ServiceCategory'} = "U";
  }

  $tmp2 = (unpack("C", pack("H*", $raw{'31x_ServiceCat'})) >> 5) & 0x3;
  #print $tmp2, "\n";

  if (exists $CallDirection_lookup{$tmp2}) {
    $clean{'31b_CallDirection'} = $CallDirection_lookup{$tmp2};
  } else {
    $clean{'31b_CallDirection'} = "U";
  }

  # 32_EndTime
  $clean{'32_EndTime'} = decode_timestamp($raw{'32_EndTime'});

  # 33_EndReason
  $tmp = unpack("I", pack("H8", $raw{'33_EndReason'}));
  if (exists $EndReason_lookup{$tmp}) {
    $clean{'33_EndReason'} = $EndReason_lookup{$tmp};
  } else {
    $clean{'33_EndReason'} = "U";
  }

  # 34_OpType
  $tmp = unpack("H2", pack("H2", $raw{'34_OpType'}));
  if (exists $OpType_lookup{$tmp}) {
    $clean{'34_OpType'} = $OpType_lookup{$tmp};
  } else {
    $clean{'34_OpType'} = "U";
  }

  # 35_ValidID
  $tmp = unpack("C", pack("H8", $raw{'35x_IDString'})) & 0b00000001;

  if ($tmp) {
    $clean{'35_ValidID'} = 'Invalid';
  } else {
    $clean{'35_ValidID'} = 'Valid';
  }

  # 36_ClockID
  $tmp = unpack("C", pack("H8", $raw{'35x_IDString'})) & 0b00000010;
  if ($tmp) {
    $clean{'36_ClockID'} = 'Clock unchanged during call';
  } else {
    $clean{'36_ClockID'} = 'Clock changed during call';
  }

  # 37_FreeID
  $tmp = unpack("C", pack("H8", $raw{'35x_IDString'})) & 0b00000100;
  if ($tmp) {
    $clean{'37_FreeID'} = 'Charge';
  } else {
    $clean{'37_FreeID'} = 'Free';
  }

  # 38_AttemptCallID
  #$tmp = unpack("C", pack("H8", $raw{'35x_IDString'})) & 0b00001000;
  #if ($tmp) {
  #  $clean{'38_AttemptCallID'} = 'Attempt call in charge';
  #} else {
  #  $clean{'38_AttemptCallID'} = 'Attempt call free';
  #}
  $clean{'38_AttemptCallID'} = '';

  # 39_AnswerID
  $tmp = unpack("C", pack("H8", $raw{'35x_IDString'})) & 0b00010000;
  if ($tmp) {
    $clean{'39_AnswerID'} = 'Answer';
  } else {
    $clean{'39_AnswerID'} = 'Not Answer';
  }

  # 40_AnaOpID
  #$clean{'40_AnaOpID'} = unpack("B8", pack("H8", $raw{'35x_IDString'}));
  $clean{'40_AnaOpID'} = '';

  # 41_AnaTpID
  $clean{'41_AnaTpID'} = '';

  # 42_OverseasID
  $tmp = unpack("C", pack("H8", $raw{'35x_IDString'})) & 0b10000000;
  if ($tmp) {
    $clean{'42_OverseasID'} = 'International Service';
  } else {
    $clean{'42_OverseasID'} = 'National Service';
  }


  # 43_InTrkGrpType
  $clean{'43_InTrkGrpType'} = '';

  # 44_InTrkGrpNo
  $clean{'44_InTrkGrpNo'} = unpack("n",
                 pack("H4", $raw{'44_InTrkGrpNo'}));

  # 45_InTrkCircuitNo
  $clean{'45_InTrkCircuitNo'} = unpack("n",
               pack("H4", $raw{'45_InTrkCircuitNo'}));

  # 46_InTrkConnectTime
  $clean{'46_InTrkConnectTime'} = decode_timestamp($raw{'46_InTrkConnectTime'});

  # 47_InTrkDisconnectTime
  $clean{'47_InTrkDisconnectTime'} = decode_timestamp($raw{'47_InTrkDisconnectTime'});

  # 48_IngressOPC
  $clean{'48_IngressOPC'} = unpack("n",
               pack("H6", $raw{'48_IngressOPC'}));

  # 49_IngressDPC
  $clean{'49_IngressDPC'} = unpack("n",
               pack("H6", $raw{'49_IngressDPC'}));

  # 50_InMGType
  $tmp = unpack("I", pack("H8", $raw{'50_InMGType'}));
  if (exists $InMGType_lookup{$tmp}) {
    $clean{'50_InMGType'} = $InMGType_lookup{$tmp};
  } else {
    $clean{'50_InMGType'} = "U";
  }

  # 51_InMGID
  $clean{'51_InMGID'} = unpack("n",
               pack("H4", $raw{'51_InMGID'}));

  # 52_bOpSSIPAddr
  $clean{'52_bOpSSIPAddr'} = decode_ipaddress($raw{'52_bOpSSIPAddr'});

  # 53_bOpMGIPAddr
  $clean{'53_bOpMGIPAddr'} = decode_ipaddress($raw{'53_bOpMGIPAddr'});

  # 54_bOpMGIPAddr
  $clean{'54_bOpRtpIPAddr'} = decode_ipaddress($raw{'54_bOpRtpIPAddr'});

  # 55_bOpProtocol
  $tmp = unpack("I", pack("H8", $raw{'55_bOpProtocol'}));
  if (exists $bOpProtocol_lookup{$tmp}) {
    $clean{'55_bOpProtocol'} = $bOpProtocol_lookup{$tmp};
  } else {
    $clean{'55_bOpProtocol'} = "U";
  }

  # 56_bCallDirect
  $tmp = unpack("I", pack("H8", $raw{'56_bCallDirect'}));
  if (exists $bCallDirect_lookup{$tmp}) {
    $clean{'56_bCallDirect'} = $bCallDirect_lookup{$tmp};
  } else {
    $clean{'56_bCallDirect'} = "U";
  }

  # 57_bCallType
  $tmp = unpack("I", pack("H8", $raw{'57_bCallType'}));
  if (exists $bCallType_lookup{$tmp}) {
    $clean{'57_bCallType'} = $bCallType_lookup{$tmp};
  } else {
    $clean{'57_bCallType'} = "U";
  }

  # 58_bOpCoding
  $tmp = unpack("I", pack("H8", $raw{'58_bOpCoding'}));
  if (exists $bOpCoding_lookup{$tmp}) {
    $clean{'58_bOpCoding'} = $bOpCoding_lookup{$tmp};
  } else {
    $clean{'58_bOpCoding'} = "U";
  }

  # 59_bCallParty
  $clean{'59_bCallParty'} = '';

  # 60_OutTrkGrpType
  $clean{'60_OutTrkGrpType'} = '';

  # 61_OutTrkGrpNo
  $clean{'61_OutTrkGrpNo'} = unpack("n",
                 pack("H4", $raw{'61_OutTrkGrpNo'}));

  # 62_OutTrkCircuitNo
  $clean{'62_OutTrkCircuitNo'} = unpack("n",
               pack("H4", $raw{'62_OutTrkCircuitNo'}));

  # 63_OutTrkConnectTime
  $clean{'63_OutTrkConnectTime'} = decode_timestamp($raw{'63_OutTrkConnectTime'});

  # 64_OutTrkDisconnectTime
  $clean{'64_OutTrkDisconnectTime'} = decode_timestamp($raw{'64_OutTrkDisconnectTime'});

  # 65_EgressOPC
  $clean{'65_EgressOPC'} = unpack("n",
               pack("H6", $raw{'65_EgressOPC'}));

  # 66_EgressDPC
  $clean{'66_EgressDPC'} = unpack("n",
               pack("H6", $raw{'66_EgressDPC'}));

  # 67_OutMGType
  $tmp = unpack("I", pack("H8", $raw{'67_OutMGType'}));
  if (exists $InMGType_lookup{$tmp}) {
    $clean{'67_OutMGType'} = $InMGType_lookup{$tmp};
  } else {
    $clean{'67_OutMGType'} = "U";
  }

  # 68_OutMGID
  $clean{'68_OutMGID'} = unpack("n",
               pack("H4", $raw{'68_OutMGID'}));

  # 69_bTpSSIPAddr
  $clean{'69_bTpSSIPAddr'} = decode_ipaddress($raw{'69_bTpSSIPAddr'});

  # 70_bTpMGIPAddr
  $clean{'70_bTpMGIPAddr'} = decode_ipaddress($raw{'70_bTpMGIPAddr'});

  # 71_bTpRtpIPAddr
  $clean{'71_bTpRtpIPAddr'} = decode_ipaddress($raw{'71_bTpRtpIPAddr'});

  # 72_bTpProtocol
  $tmp = unpack("I", pack("H8", $raw{'72_bTpProtocol'}));
  if (exists $bOpProtocol_lookup{$tmp}) {
    $clean{'72_bTpProtocol'} = $bOpProtocol_lookup{$tmp};
  } else {
    $clean{'72_bTpProtocol'} = "U";
  }

  # 73_dwFaxPage
  $clean{'73_dwFaxPage'} = '';

  # 74_SS
  $clean{'74_SS'} = unpack("n",
               pack("H14", $raw{'74_SS'}));;

  # 75_ChargeID
  $tmp = unpack("I", pack("H8", $raw{'75_ChargeID'}));
  if (exists $ChargeID_lookup{$tmp}) {
    $clean{'75_ChargeID'} = $ChargeID_lookup{$tmp};
  } else {
    $clean{'75_ChargeID'} = "U";
  }

  # 76_LinkProp
  $tmp = unpack("I", pack("H8", $raw{'76_LinkProp'}));
  if (exists $OpProp_lookup{$tmp}) {
    $clean{'76_LinkProp'} = $OpProp_lookup{$tmp};
  } else {
    $clean{'76_LinkProp'} = "U";
  }

  # 77_LinkNo
  $tmp = unpack("H64", pack("h64", $raw{'77_LinkNo'}));
  $clean{'77_LinkNo'} = clean_bcd($tmp);

  # 78_LinkNet
  $clean{'78_LinkNet'} = unpack("I",
                     pack("H8", $raw{'78_LinkNet'}));

  # 79_LinkLata
  $tmp = unpack("H4",
         pack("h2 h2",
              $raw{'79b_LinkLata'},
              $raw{'79a_LinkLata'}));
  $clean{'79_LinkLata'} = clean_bcd($tmp);

  # 80_Fee
  $clean{'80_Fee'} = unpack("H8", pack("h8", $raw{'80_Fee'}));

  # 81_CustomerID
  $clean{'81_CustomerID'} = unpack("n", pack("H8", $raw{'80_Fee'}));

  # 82_CustLocationID
  $clean{'82_CustLocationID'} = unpack("n", pack("H8", $raw{'82_CustLocationID'}));

  # 83_AccountCodeType
  $clean{'83_AccountCodeType'} = '';

  # 84_AccountCode
  $clean{'84_AccountCode'} = '';

  # 85_AccessNumber
  $clean{'85_AccessNumber'} = unpack("H8", pack("h8", $raw{'85_AccessNumber'}));

  # 86_CarrierID
  $clean{'86_CarrierID'} = unpack("H8", pack("h8", $raw{'86_CarrierID'}));

  # 87_OpCtxNo
  $clean{'87_OpCtxNo'} = unpack("n", pack("H4", $raw{'87_OpCtxNo'}));

  # 88_TpCtxNo
  $clean{'88_TpCtxNo'} = unpack("n", pack("H4", $raw{'88_TpCtxNo'}));

  # 89_IngresBytes
  $clean{'89_IngresBytes'} = '';

  # 90_EgresBytes
  $clean{'90_EgresBytes'} = '';

  # 91_AuthorityType
  $clean{'91_AuthorityType'} = '';

  # 92_Filler1
  $clean{'92_Filler1'} = '';

  # 93_Filler2
  $clean{'93_Filler2'} = '';

  # 94_AuthorityCode
  $clean{'94_AuthorityCode'} = '';

  # 95_CarrierSelectInfo
  $clean{'95_CarrierSelectInfo'} = unpack("n", pack("H4", $raw{'95_CarrierSelectInfo'}));

  # 96_BearerSvc
  $clean{'96_BearerSvc'} = '';

  # 97_TeleSvc
  $clean{'97_TeleSvc'} = '';

  # 98_USS1
  $clean{'98_USS1'} = '';

  # 99_USS3
  $clean{'99_USS3'} = unpack("C", pack("H2", $raw{'99_USS3'}));

  # 100_SpOpNo
  $clean{'x100_SpOpNo'} = '';

  # 101_SpTpNo
  $clean{'x101_SpTpNo'} = '';

  # 102_BillNoProp
  $tmp = unpack("I", pack("H8", $raw{'x102_BillNoProp'}));
  if (exists $BillNoProp_lookup{$tmp}) {
    $clean{'x102_BillNoProp'} = $BillNoProp_lookup{$tmp};
  } else {
    $clean{'x102_BillNoProp'} = "U";
  }

  # 103_BillNo
  $tmp = unpack("H64", pack("h64", $raw{'x103_BillNo'}));
  $clean{'x103_BillNo'} = clean_bcd($tmp);

  # 104_BillNet
  $clean{'x104_BillNet'} = unpack("I",
                     pack("H8", $raw{'x104_BillNet'}));

  # 105_BillLata
  $tmp = unpack("H4",
         pack("h2 h2",
              $raw{'x105b_BillLata'},
              $raw{'x105a_BillLata'}));
  $clean{'x105_BillLata'} = clean_bcd($tmp);

  # 106_TransNoProp
  $tmp = unpack("I", pack("H8", $raw{'x106_TransNoProp'}));
  if (exists $OpProp_lookup{$tmp}) {
    $clean{'x106_TransNoProp'} = $OpProp_lookup{$tmp};
  } else {
    $clean{'x106_TransNoProp'} = "U";
  }

  # 107_TransNo
  $tmp = unpack("H64", pack("h64", $raw{'x107_TransNo'}));
  $clean{'x107_TransNo'} = clean_bcd($tmp);

  # 108_TransNet
  $clean{'x108_TransNet'} = '';

  # 109_TransLata
  $tmp = unpack("H4",
         pack("h2 h2",
              $raw{'x109b_TransLata'},
              $raw{'x109a_TransLata'}));
  $clean{'x109_TransLata'} = clean_bcd($tmp);

  # 110_LocNoProp
  $tmp = unpack("I", pack("H8", $raw{'x110_LocNoProp'}));
  if (exists $OpProp_lookup{$tmp}) {
    $clean{'x110_LocNoProp'} = $OpProp_lookup{$tmp};
  } else {
    $clean{'x110_LocNoProp'} = "U";
  }

  # 111_LocNo
  $tmp = unpack("H64", pack("h64", $raw{'x111_LocNo'}));
  $clean{'x111_LocNo'} = clean_bcd($tmp);

  # 112_LocNet
  $clean{'x112_LocNet'} = unpack("I",
                     pack("H8", $raw{'x112_LocNet'}));;

  # 113_LocLata
  $clean{'x113_LocLata'} = '';

  # 114_ChgRateKind
  $tmp = unpack("H4",
         pack("h2 h2",
              $raw{'x114b_ChgRateKind'},
              $raw{'x114a_ChgRateKind'}));
  $clean{'x114_ChgRateKind'} = clean_bcd($tmp);

  # 115_ChgModulatorType
  $tmp = unpack("I", pack("H8", $raw{'x115_ChgModulatorType'}));
  if (exists $ChgModulatorType_lookup{$tmp}) {
    $clean{'x115_ChgModulatorType'} = $ChgModulatorType_lookup{$tmp};
  } else {
    $clean{'x115_ChgModulatorType'} = "U";
  }

  # 116_ChgModulatorVal
  $clean{'x116_ChgModulatorVal'} = unpack("I",
                     pack("H8", $raw{'x116_ChgModulatorVal'}));


  # 117_InAttachFeeKind
  $tmp = unpack("H8", pack("h8", $raw{'x117_InAttachFeeKind'}));
  if (exists $InAttachFeeKind_lookup{$tmp}) {
    $clean{'x117_InAttachFeeKind'} = $InAttachFeeKind_lookup{$tmp};
  } else {
    $clean{'x117_InAttachFeeKind'} = "U";
  }

  # 118_InAttachFeeVal (to be implemented)
  $clean{'x118_InAttachFeeVal'} = unpack("N",
                     pack("H8", $raw{'x118_InAttachFeeVal'}));

  # 119_TransparentParameter
  #$clean{'119_TransparentParameter'} = oct("0b" . $raw{'119_TransparentParameter'});
  $clean{'x119_TransparentParameter'} = oct("0b" . $raw{'x119_TransparentParameter'});

  ###############
  # Step 3 - Output the translated values
  ###############


  #
  # Output the field/value pairs in a consistent, RDBMS-ready fashion
  #

  foreach $name (sort (keys %clean)) {
    $fieldname = $name;
    $fieldname =~ s/[0-9a-z]+_//; # Strip off the field number
    if ($CSV_Header) {
      #print STDOUT "${fieldname},";
    }
  }

  if ($CSV_Header) {
        $CSV_Header = 0;
        #print STDOUT "\n";
    }

  foreach $name (sort (keys %clean)) {
    print STDOUT "\"$clean{$name}\",";
  }

  print STDOUT "\n";

  if ($Verbose) {
    foreach $name (sort (keys %raw)) {
      print STDOUT "${name}=$raw{$name},";
      print STDOUT "\n";
    }
    print STDOUT "\n";
    print STDOUT "recordcount is $recordcount\n";
  }
  $recordcount++;

}

