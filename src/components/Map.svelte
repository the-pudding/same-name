<script>
	import { max, color, groups, scalePow, scaleLog, csvFormat } from "d3";
	import Figure from "$components/Figure.svelte";
	import MapSvg from "$components/Figure.MapSvg.svelte";
	import MapCanvas from "$components/Figure.MapCanvas.svelte";
	import MapPath from "$components/Figure.MapPath.svelte";
	import MapPoints from "$components/Figure.MapPoints.svelte";
	import MapLabels from "$components/Figure.MapLabels.svelte";
	import MapKey from "$components/Figure.MapKey.svelte";
	import { counties, states } from "$data/us.js";
	import addDataToCounties from "$data/addDataToCounties.js";
	import colors from "$data/colors2.json";

	const aspectRatio = "975/610";
	const projectionObject = states;
	const stateFeatures = states.features;

	let scalePop;
	let scaleWiki;
	let scaleDist;

	export let placeData;

	export let scaleTypePop = "scalePow";
	export let scaleTypeWiki = "scalePow";
	export let scaleTypeDist = "scaleLog";

	export let scaleExpPop = "0.67";
	export let scaleExpWiki = "0.67";
	export let scaleExpDist = "1";

	export let scaleBoundsPop = [0, 490000];
	export let scaleBoundsWiki = [0, 87500];
	export let scaleBoundsDist = [80, 320];

	export let valueWeightDist = "2";
	export let valueWeightPop = "1";
	export let valueWeightWiki = "1";

	export let thresholdLower = 0.5;
	export let thresholdUpper = 0.75;
	export let valueProp = "share";

	function getLabel(d) {
		const post =
			d.level === "city-us"
				? `, ${d.state}`
				: d.level === "city-international"
				? ` (${d.country})`
				: ` (${d.level})`;
		return `${d.name}${post}`;
	}

	// function getSampleFillDist(id, data) {
	// 	const match = data.find((d) => d.id === id);
	// 	const c = color("#fff");
	// 	c.opacity = Math.max(
	// 		0.1,
	// 		Math.floor((match.scoreD / +valueWeightDist) * 10) / 10
	// 	);
	// 	return c.toString();
	// }

	// function getSampleFillShare(id, data) {
	// 	const match = data.find((d) => d.id === id);
	// 	const c = color("#fff");
	// 	c.opacity = Math.max(0.1, Math.floor(match.share * 10) / 10);
	// 	return c.toString();
	// }

	$: places = placeData.map((d, i) => ({
		...d,
		population: +d.population,
		wiki: +d.wiki,
		latitude: +d.latitude,
		longitude: +d.longitude,
		label: getLabel(d),
		className: i > colors.length - 2 ? "hide-label" : "",
		fill: colors[i] || colors[colors.length - 1]
	}));

	$: placeFeatures = places.map((d) => ({
		type: "Feature",
		geometry: {
			type: "Point",
			coordinates: [d.longitude, d.latitude]
		},
		properties: d
	}));

	$: maxValue =
		valueProp === "share"
			? 1
			: +valueWeightDist + +valueWeightPop + +valueWeightWiki;

	$: maxScore = max(
		countiesWithData.features,
		(d) => d.properties.data[0][valueProp]
	);

	$: getTopScoreFill = (data) => {
		const match = data[0];
		let c = color(match.fill);
		if (match[valueProp] < thresholdLower * maxScore) c = color("#666");
		else if (match[valueProp] < thresholdUpper * maxScore) c.opacity = 0.75;
		else c.opacity = 1;
		return c.toString();
	};

	$: {
		const sd =
			scaleTypeDist === "scaleLog"
				? scaleLog()
				: scalePow().exponent(+scaleExpDist);
		scaleDist = sd
			.domain(scaleBoundsDist)
			.range([+valueWeightDist, 0])
			.clamp(true);

		const sp =
			scaleTypePop === "scaleLog"
				? scaleLog()
				: scalePow().exponent(+scaleExpPop);
		scalePop = sp
			.domain(scaleBoundsPop)
			.range([0, +valueWeightPop])
			.clamp(true);

		const sw =
			scaleTypeWiki === "scaleLog"
				? scaleLog()
				: scalePow().exponent(+scaleExpWiki);
		scaleWiki = sp
			.domain(scaleBoundsWiki)
			.range([0, +valueWeightWiki])
			.clamp(true);
	}

	$: countiesWithData = addDataToCounties({
		valueProp,
		counties,
		places,
		scaleDist,
		scalePop,
		scaleWiki
	});

	// $: if (countiesWithData) {
	// 	const x = countiesWithData.features.find(
	// 		(d) => d.properties.name === "Berkshire"
	// 	).properties.data;
	// 	// window.output = csvFormat(x);
	// 	console.table(
	// 		x.map((d) => {
	// 			return {
	// 				label: d.label,
	// 				dist: d.dist,
	// 				population: d.population,
	// 				wiki: d.wiki,
	// 				scoreD: +d.scoreD.toFixed(2),
	// 				scoreP: +d.scoreP.toFixed(2),
	// 				scoreW: +d.scoreW.toFixed(2),
	// 				score: +d.score.toFixed(2),
	// 				share: +d.share.toFixed(2)
	// 			};
	// 		})
	// 	);
	// }

	$: countyFeatures = countiesWithData.features.map((d) => ({
		...d,
		properties: {
			...d.properties,
			fill: getTopScoreFill(d.properties.data)
		}
	}));
</script>

<Figure --aspect-ratio={aspectRatio} custom={{ projectionObject }}>
	<MapCanvas features={countyFeatures} stroke="rgba(0, 0, 0, 0.25)" />
	<MapSvg>
		<!-- <MapPath features={featuresCounties} stroke="rgba(0, 0, 0, 0.25)" /> -->
		<MapPath features={stateFeatures} stroke="rgba(0, 0, 0, 0.5)" />
		<MapPoints
			features={placeFeatures.filter((d) => d.properties.level === "city-us")}
			stroke="#000"
			strokeWidth="2"
			radius="5"
		/>
		<MapLabels
			features={placeFeatures.filter((d) => d.properties.level === "city-us")}
			stroke="#000"
			strokeWidth="4"
			offsetY={-12}
		/>
	</MapSvg>
	<!-- svelte-ignore a11y-structure -->
	<!-- <figcaption slot="figcaption"></figcaption> -->
</Figure>
<MapKey features={placeFeatures} />