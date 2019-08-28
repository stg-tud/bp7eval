package main

import (
	"fmt"
	"log"
	"time"

	"github.com/dtn7/dtn7-go/bundle"
)

type EncodedBundle []byte

func bench_bundle_create_builder(runs int, crc_type bundle.CRCType) []EncodedBundle {
	var bundles []EncodedBundle
	start := time.Now()
	fmt.Printf("Creating %d bundles with CRC_%s using builder: \t", runs, crc_type)
	for i := 0; i < runs; i++ {
		bndl, err := bundle.Builder().
			CRC(crc_type).
			Source("dtn:node1/123456").
			Destination("dtn:node2/inbox").
			CreationTimestampNow().
			Lifetime(60 * 60 * 1000000).
			BundleAgeBlock(0).
			PayloadBlock([]byte("AAA")).
			Build()
		if err != nil {
			log.Fatal("This should not happen, encoding error! ", err)
		}
		//bndl.CalculateCRC()
		bundles = append(bundles, bndl.ToCbor())
	}

	elapsed := time.Since(start)
	fmt.Printf("%d bundles/second\n", int(float64(runs)/(elapsed.Seconds())))
	return bundles
}

func bench_bundle_create(runs int, crc_type bundle.CRCType) []EncodedBundle {
	var bundles []EncodedBundle
	start := time.Now()

	fmt.Printf("Creating %d bundles with CRC_%s: \t\t", runs, crc_type)
	for i := 0; i < runs; i++ {
		var bndl, err = bundle.NewBundle(
			bundle.NewPrimaryBlock(
				0,
				bundle.MustNewEndpointID("dtn:node2/inbox"),
				bundle.MustNewEndpointID("dtn:node1/123456"),
				bundle.NewCreationTimestamp(bundle.DtnTimeNow(), 0),
				60*60*1000000),
			[]bundle.CanonicalBlock{
				bundle.NewBundleAgeBlock(1, 0, 0),
				bundle.NewPayloadBlock(0, []byte("AAA")),
			})
		if err != nil {
			log.Fatal("This should not happen, encoding error! ", err)
		}
		bndl.SetCRCType(crc_type)
		bndl.CalculateCRC()
		bundles = append(bundles, bndl.ToCbor())
	}
	elapsed := time.Since(start)
	fmt.Printf("%d bundles/second\n", int(float64(runs)/(elapsed.Seconds())))
	return bundles
}

func bench_bundle_encode(runs int, crc_type bundle.CRCType) []EncodedBundle {
	var bundles []EncodedBundle
	var bndl, err = bundle.NewBundle(
		bundle.NewPrimaryBlock(
			0,
			bundle.MustNewEndpointID("dtn:node2/inbox"),
			bundle.MustNewEndpointID("dtn:node1/123456"),
			bundle.NewCreationTimestamp(bundle.DtnTimeNow(), 0),
			60*60*1000000),
		[]bundle.CanonicalBlock{
			bundle.NewBundleAgeBlock(1, 0, 0),
			bundle.NewPayloadBlock(0, []byte("AAA")),
		})
	if err != nil {
		log.Fatal("This should not happen, encoding error! ", err)
	}
	bndl.SetCRCType(crc_type)

	start := time.Now()

	fmt.Printf("Encoding %d bundles with CRC_%s: \t\t", runs, crc_type)
	for i := 0; i < runs; i++ {
		bndl.PrimaryBlock.Lifetime++
		bndl.CalculateCRC()
		bundles = append(bundles, bndl.ToCbor())
	}
	elapsed := time.Since(start)
	fmt.Printf("%d bundles/second\n", int(float64(runs)/(elapsed.Seconds())))
	return bundles
}

func bench_bundles_load(bundles []EncodedBundle, crc_type bundle.CRCType) {
	start := time.Now()

	fmt.Printf("Loading %d bundles with CRC_%s: \t\t\t", len(bundles), crc_type)

	for _, element := range bundles {
		var b []byte = element
		_, err := bundle.NewBundleFromCbor(&b)
		if err != nil {
			log.Fatal("Loading error: ", err)
		}
	}

	elapsed := time.Since(start)
	fmt.Printf("%d bundles/second\n", int(float64(len(bundles))/(elapsed.Seconds())))
}

func testEq(a, b EncodedBundle) bool {

	// If one is nil, the other must also be nil.
	if (a == nil) != (b == nil) {
		return false
	}

	if len(a) != len(b) {
		return false
	}

	for i := range a {
		if a[i] != b[i] {
			return false
		}
	}

	return true
}

func main() {
	/*bench_bundle_create_builder(100000, bundle.CRCNo)
	bench_bundle_create_builder(100000, bundle.CRC16)
	bench_bundle_create_builder(100000, bundle.CRC32)*/

	/*spew.Dump(builder_bundles_no[0])
	println(hex.EncodeToString(builder_bundles_no[0]))*/
	fmt.Println("warmup")
	bundles_no := bench_bundle_create(100000, bundle.CRCNo)
	bundles_16 := bench_bundle_create(100000, bundle.CRC16)
	bundles_32 := bench_bundle_create(100000, bundle.CRC32)

	bench_bundle_encode(100000, bundle.CRCNo)
	bench_bundle_encode(100000, bundle.CRC16)
	bench_bundle_encode(100000, bundle.CRC32)

	bench_bundles_load(bundles_no, bundle.CRCNo)
	bench_bundles_load(bundles_16, bundle.CRC16)
	bench_bundles_load(bundles_32, bundle.CRC32)
	fmt.Println("begin")
	for i := 0; i < 2; i++ {
		bundles_no := bench_bundle_create(100000, bundle.CRCNo)
		bundles_16 := bench_bundle_create(100000, bundle.CRC16)
		bundles_32 := bench_bundle_create(100000, bundle.CRC32)

		bench_bundle_encode(100000, bundle.CRCNo)
		bench_bundle_encode(100000, bundle.CRC16)
		bench_bundle_encode(100000, bundle.CRC32)

		bench_bundles_load(bundles_no, bundle.CRCNo)
		bench_bundles_load(bundles_16, bundle.CRC16)
		bench_bundles_load(bundles_32, bundle.CRC32)
		fmt.Println(" ")
	}
	fmt.Println("end")
}
