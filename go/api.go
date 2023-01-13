package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"strconv"
	"time"
)

var API_KEY string = "3b43e7037a0e4aef1b57a5352544293c89bc0ddfa8e354fb101a640ce37ef4be"
var pathLog string = "/tmp/log_threat/"

type PulsesId struct {
	Results          []string    `json:"results"`
	Count            int         `json:"count"`
	PrefetchPulseIds bool        `json:"prefetch_pulse_ids"`
	T                int         `json:"t"`
	T2               float64     `json:"t2"`
	T3               float64     `json:"t3"`
	Previous         interface{} `json:"previous"`
	Next             string      `json:"next"`
}

func main() {

	pulseIds := getPulseIds()
	getReports(pulseIds)

	getReportAllSubscribedPulse()
}

func getReports(pulseIds []string) {

	fmt.Printf("start get report. [%s]\n", time.Now())

	url := "https://otx.alienvault.com/api/v1/pulses/related?pulse_id="

	for index, id := range pulseIds {
		fileName := "response" + strconv.Itoa(index)
		getReport(url+id, fileName)
	}

	fmt.Printf("finished report. [%s]\n", time.Now())
}

func getPulseIds() []string {

	var ids []string

	url := "https://otx.alienvault.com/api/v1/pulses/subscribed_pulse_ids"
	// create request
	request, err := http.NewRequest("GET", url, nil)

	if err != nil {
		fmt.Println(err.Error())
	} else {
		request.Header.Add("accept", "application/json")
		request.Header.Add("X-OTX-API-KEY", API_KEY)

		response, err := http.DefaultClient.Do(request)

		if err != nil {
			fmt.Println(err.Error())
		} else {
			defer response.Body.Close()

			body, _ := ioutil.ReadAll(response.Body)

			data := PulsesId{}
			_ = json.Unmarshal([]byte(body), &data)

			ids = data.Results
		}
	}

	fmt.Printf("pulse ids get. [%s]\n", time.Now())

	return ids
}

func getReportAllSubscribedPulse() {

	url := "https://otx.alienvault.com/api/v1/pulses/subscribed"

	fmt.Printf("start get report all. [%s]\n", time.Now())

	getReport(url, "all-subscribed-Pulse")
}

func getReport(url string, name string) {

	request, err := http.NewRequest("GET", url, nil)

	if err != nil {
		fmt.Println(err.Error())
	} else {
		request.Header.Add("accept", "application/json")
		request.Header.Add("X-OTX-API-KEY", API_KEY)

		response, err := http.DefaultClient.Do(request)

		if err != nil {
			fmt.Println(err.Error())
		} else {
			defer response.Body.Close()

			body, _ := ioutil.ReadAll(response.Body)

			fileName := pathLog + name + ".json"
			err = ioutil.WriteFile(fileName, body, 0644)

			if err != nil {
				fmt.Println(err.Error())
			}
		}
	}
}
