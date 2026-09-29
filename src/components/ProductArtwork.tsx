import Svg, { Ellipse, G, Line, Path, Rect, Text } from 'react-native-svg';

import type { Product } from '../types/catalog';

// Illustration-only shades keep the mock packaging consistent across the catalog.
const palette = {
  orange: '#F46A25',
  orangeLight: '#FFB285',
  orangeDark: '#CF4F13',
  ink: '#20251F',
  cream: '#FAF6E9',
  creamShade: '#E8E1CE',
  white: '#FFFFFF',
  sage: '#A9BC99',
  sageDark: '#536E4A',
  green: '#DCE6D5',
  cocoa: '#705243',
  cocoaDark: '#48342D',
  shadow: '#243223',
};

function Ground({ width = 45 }: { width?: number }) {
  return <Ellipse cx={80} cy={139} rx={width} ry={6} fill={palette.shadow} opacity={0.09} />;
}

function Whey() {
  return (
    <>
      <Ground width={43} />
      <Path d="M45 41H116L113 126Q111 137 80 138Q49 137 47 127Z" fill={palette.cream} />
      <Path d="M103 44H116L113 126Q112 133 103 135Z" fill={palette.creamShade} />
      <Rect x={42} y={28} width={76} height={21} rx={6} fill={palette.ink} />
      <Ellipse cx={80} cy={29} rx={35} ry={4} fill="#42493F" />
      <Line x1={48} y1={42} x2={112} y2={42} stroke="#51584E" strokeWidth={1.5} />
      <Path d="M46 62H115L113 112Q80 120 48 112Z" fill={palette.orange} />
      <Path d="M104 62H115L113 112L103 114Z" fill={palette.orangeDark} opacity={0.4} />
      <Text x={56} y={79} fontSize={10} fontWeight="900" fill={palette.cream}>PROTO</Text>
      <Text x={55} y={98} fontSize={17} fontWeight="900" fill={palette.cream}>WHEY</Text>
      <Text x={56} y={106} fontSize={4.7} fontWeight="700" letterSpacing={1} fill={palette.cream}>DAILY PROTEIN</Text>
      <Path d="M55 121H80M55 125H70" stroke={palette.sageDark} strokeWidth={2} strokeLinecap="round" opacity={0.5} />
      <Path d="M94 121L99 117L103 121L99 125Z" fill={palette.orange} />
    </>
  );
}

function Bar() {
  return (
    <>
      <Ground width={54} />
      <G rotation={-17} origin="80, 83">
        <Path d="M21 61L28 58L32 61L36 58H132L136 62L140 59V108L136 105L132 109H34L30 106L25 109L21 106Z" fill={palette.cream} />
        <Path d="M24 64V103M28 64V103M134 65V102M138 66V101" stroke={palette.creamShade} strokeWidth={1.5} />
        <Path d="M35 58H104V109H35Z" fill={palette.sageDark} />
        <Path d="M35 101H104V109H35Z" fill="#415B3C" />
        <Text x={44} y={75} fontSize={8} fontWeight="900" fill={palette.cream}>PROTO</Text>
        <Text x={43} y={91} fontSize={11} fontWeight="900" fill={palette.cream}>PROTEIN</Text>
        <Text x={44} y={102} fontSize={9} fontWeight="700" fill={palette.cream}>BAR</Text>
        <Path d="M105 78L119 69L132 77L119 87Z" fill={palette.cocoa} />
        <Path d="M105 78V93L119 101V87Z" fill={palette.cocoaDark} />
        <Path d="M119 87L132 77V93L119 101Z" fill="#8F6950" />
        <Path d="M113 76L126 84M113 83L126 76" stroke="#B9916A" strokeWidth={1.2} />
        <Ellipse cx={123} cy={64} rx={2} ry={1} fill={palette.orange} />
      </G>
    </>
  );
}

function Yogurt() {
  return (
    <>
      <Ground width={40} />
      <Path d="M37 62H123L113 123Q110 137 80 137Q50 137 47 123Z" fill={palette.cream} />
      <Path d="M110 66H121L112 125Q110 132 101 134Z" fill={palette.creamShade} />
      <Path d="M40 74H120L115 110Q81 116 45 110Z" fill={palette.sage} />
      <Ellipse cx={80} cy={63} rx={44} ry={10} fill={palette.sageDark} />
      <Ellipse cx={80} cy={59} rx={44} ry={10} fill={palette.cream} />
      <Ellipse cx={80} cy={58} rx={36} ry={7} fill={palette.green} />
      <Path d="M117 54L131 53L123 63Z" fill={palette.creamShade} />
      <Text x={55} y={89} fontSize={10} fontWeight="900" fill={palette.sageDark}>PROTO</Text>
      <Text x={57} y={102} fontSize={9} fontWeight="800" fill={palette.sageDark}>GREEK</Text>
      <Text x={58} y={124} fontSize={6.5} fontWeight="700" letterSpacing={1} fill={palette.sageDark}>YOGURT</Text>
      <Path d="M72 45Q66 37 73 32Q81 31 81 43Q86 30 92 34Q97 41 84 46" fill={palette.sageDark} />
    </>
  );
}

function Eggs() {
  return (
    <>
      <Ground width={54} />
      <Path d="M26 77L38 49Q41 42 50 43H122Q131 44 130 52L123 78Z" fill={palette.sageDark} />
      <Path d="M34 70L43 52Q44 49 51 50H117Q122 50 121 55L117 70Z" fill={palette.sage} />
      <Text x={58} y={64} fontSize={8} fontWeight="900" letterSpacing={1.5} fill={palette.sageDark}>PROTO</Text>
      <Path d="M21 90L36 72H123L140 91L131 124Q129 132 120 134H41Q30 132 29 123Z" fill={palette.creamShade} />
      <Ellipse cx={53} cy={86} rx={14} ry={18} fill="#EBD9B8" />
      <Ellipse cx={81} cy={84} rx={14} ry={19} fill="#F5E6CA" />
      <Ellipse cx={109} cy={85} rx={14} ry={18} fill="#EBD9B8" />
      <Ellipse cx={43} cy={101} rx={15} ry={21} fill="#F5E6CA" />
      <Ellipse cx={79} cy={101} rx={15} ry={22} fill="#FAEED6" />
      <Ellipse cx={116} cy={100} rx={15} ry={21} fill="#F5E6CA" />
      <Path d="M21 97L37 107L61 104L79 112L98 103L124 107L140 97L132 126Q131 133 122 135H39Q29 132 28 125Z" fill={palette.sage} />
      <Path d="M22 98L37 107L61 104L79 112L98 103L124 107L140 98" fill="none" stroke={palette.sageDark} strokeWidth={2} opacity={0.3} />
      <Rect x={60} y={112} width={39} height={21} rx={3} fill={palette.cream} />
      <Text x={66} y={121} fontSize={6} fontWeight="900" fill={palette.sageDark}>FARM FRESH</Text>
      <Text x={70} y={129} fontSize={7} fontWeight="900" fill={palette.sageDark}>EGGS</Text>
    </>
  );
}

function Milk() {
  return (
    <>
      <Ground width={34} />
      <Path d="M47 54L62 30H99L114 54V132L96 140L47 131Z" fill={palette.cream} />
      <Path d="M96 55L99 30L114 54V132L96 140Z" fill={palette.creamShade} />
      <Path d="M47 54L62 30H99L96 54Z" fill={palette.sage} />
      <Path d="M62 30V24H99V30" fill={palette.cream} stroke={palette.creamShade} strokeWidth={1.5} />
      <Path d="M47 79H96V130L47 123Z" fill={palette.sageDark} />
      <Path d="M96 79L114 74V125L96 130Z" fill="#415B3C" />
      <Text x={54} y={73} fontSize={9} fontWeight="900" fill={palette.sageDark}>PROTO</Text>
      <Text x={54} y={99} fontSize={14} fontWeight="900" fill={palette.cream}>MILK</Text>
      <Text x={54} y={109} fontSize={4.8} fontWeight="700" letterSpacing={1} fill={palette.cream}>EVERYDAY GOOD</Text>
      <Path d="M81 116Q73 125 81 128Q89 125 81 116Z" fill={palette.cream} />
      <Ellipse cx={83} cy={43} rx={8} ry={5} fill={palette.white} />
      <Ellipse cx={83} cy={41} rx={7} ry={4} fill={palette.cream} />
    </>
  );
}

function Paneer() {
  return (
    <>
      <Ground width={48} />
      <G rotation={-8} origin="80, 87">
        <Path d="M33 43Q80 37 125 45L127 127Q81 137 32 127Z" fill={palette.cream} />
        <Path d="M33 43Q79 37 125 45L125 52Q80 45 33 50ZM32 121Q80 128 127 121V127Q81 137 32 127Z" fill={palette.creamShade} />
        <Path d="M32 62H126V92H32Z" fill={palette.orange} />
        <Text x={42} y={77} fontSize={11} fontWeight="900" fill={palette.cream}>PROTO</Text>
        <Text x={43} y={87} fontSize={6.5} fontWeight="700" letterSpacing={1.1} fill={palette.cream}>FRESH PANEER</Text>
        <Path d="M45 109L60 99L77 105L62 116Z" fill={palette.white} />
        <Path d="M45 109V120L62 126V116Z" fill="#E1D8C3" />
        <Path d="M62 116L77 105V116L62 126Z" fill="#F2EBD9" />
        <Path d="M72 102L86 94L103 100L88 110Z" fill={palette.white} />
        <Path d="M72 102V113L88 119V110Z" fill="#E1D8C3" />
        <Path d="M88 110L103 100V112L88 119Z" fill="#F2EBD9" />
        <Path d="M105 115Q99 104 111 101Q116 109 105 115ZM107 116Q113 106 120 110Q120 119 107 116Z" fill={palette.sageDark} />
      </G>
    </>
  );
}

function Shake() {
  return (
    <>
      <Ground width={32} />
      <Path d="M64 40H97V50Q98 57 108 64Q112 68 112 77V124Q112 138 80 138Q49 138 49 124V77Q49 68 54 64Q63 57 64 50Z" fill={palette.cream} />
      <Path d="M96 43V51Q96 57 106 65Q112 70 112 78V124Q112 132 102 135V75Q102 67 93 63Q87 58 87 45Z" fill={palette.creamShade} />
      <Rect x={61} y={28} width={38} height={17} rx={4} fill={palette.sageDark} />
      <Line x1={67} y1={32} x2={93} y2={32} stroke={palette.sage} strokeWidth={1.5} />
      <Path d="M49 77H112V119Q80 126 49 119Z" fill={palette.cocoa} />
      <Text x={59} y={91} fontSize={9} fontWeight="900" fill={palette.cream}>PROTO</Text>
      <Text x={58} y={105} fontSize={9} fontWeight="900" fill={palette.cream}>PROTEIN</Text>
      <Text x={58} y={115} fontSize={9} fontWeight="900" fill={palette.cream}>SHAKE</Text>
      <Path d="M72 62L80 54L88 62L80 70Z" fill={palette.orange} />
      <Path d="M59 130H84" stroke={palette.sageDark} strokeWidth={2} strokeLinecap="round" opacity={0.4} />
    </>
  );
}

function Shaker() {
  return (
    <>
      <Ground width={34} />
      <Path d="M46 56H116L106 128Q105 138 80 138Q56 138 55 128Z" fill={palette.green} />
      <Path d="M104 58H116L106 128Q105 134 98 136Z" fill={palette.sage} />
      <Path d="M48 59L57 123Q59 130 65 131" fill="none" stroke={palette.white} strokeWidth={3} opacity={0.7} />
      <Path d="M45 47Q47 40 54 39H107Q115 40 117 47L119 59H43Z" fill={palette.ink} />
      <Rect x={58} y={29} width={35} height={14} rx={5} fill={palette.orange} />
      <Path d="M91 37L99 25Q102 19 109 22L115 26Q119 29 116 34L106 46" fill="none" stroke={palette.ink} strokeWidth={6} strokeLinecap="round" />
      <Path d="M48 52H113" stroke="#4A5145" strokeWidth={2} />
      <Text x={65} y={103} fontSize={31} fontWeight="900" fill={palette.sageDark}>P</Text>
      <Text x={63} y={116} fontSize={6} fontWeight="800" letterSpacing={1.1} fill={palette.sageDark}>PROTO</Text>
      <Path d="M97 74H104M97 83H103M97 92H102M97 101H101" stroke={palette.sageDark} strokeWidth={1.4} opacity={0.5} />
    </>
  );
}

const illustrations = {
  whey: Whey,
  bar: Bar,
  yogurt: Yogurt,
  eggs: Eggs,
  milk: Milk,
  paneer: Paneer,
  shake: Shake,
  shaker: Shaker,
};

type ProductArtworkProps = {
  kind: Product['artwork'];
  size?: number;
};

export function ProductArtwork({ kind, size = 120 }: ProductArtworkProps) {
  const Illustration = illustrations[kind];

  return (
    <Svg width={size} height={size} viewBox="0 0 160 160" accessible={false}>
      <Illustration />
    </Svg>
  );
}
